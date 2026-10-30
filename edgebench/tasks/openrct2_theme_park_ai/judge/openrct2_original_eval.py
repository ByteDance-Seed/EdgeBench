#!/usr/bin/env python3
"""
OpenRCT2 AI Plugin Evaluation Script

Runs the given AI plugin on each scenario in host --headless mode and scores
it from a judge-owned monitor plugin. The submitted plugin's stdout is not
trusted for score or termination.
"""

import argparse
import os
import re
import selectors
import secrets
import signal
import subprocess
import sys
import time

OPENRCT2_DIR = os.environ.get(
    "OPENRCT2_DIR",
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "release", "OpenRCT2"),
)
OPENRCT2_CLI = os.path.join(OPENRCT2_DIR, "openrct2-cli")
DATA_PATH = os.path.join(OPENRCT2_DIR, "data")
PLUGIN_DIR = os.path.expanduser("~/.config/OpenRCT2/plugin")

BASELINES = {
    "scenario_small.park": 49420,
    "scenario_medium.park": 87360,
    "scenario_large.park": 46970,
}

MIN_MAX_RIDES = int(os.environ.get("OPENRCT2_MIN_MAX_RIDES", "1"))
MIN_MAX_OPEN_RIDES = int(os.environ.get("OPENRCT2_MIN_MAX_OPEN_RIDES", "1"))
MIN_MAX_STAFF = int(os.environ.get("OPENRCT2_MIN_MAX_STAFF", "1"))
MIN_RIDE_SAMPLE_RATIO = float(os.environ.get("OPENRCT2_MIN_RIDE_SAMPLE_RATIO", "0.25"))
MIN_OPEN_RIDE_SAMPLE_RATIO = float(os.environ.get("OPENRCT2_MIN_OPEN_RIDE_SAMPLE_RATIO", "0.25"))
MIN_STAFF_SAMPLE_RATIO = float(os.environ.get("OPENRCT2_MIN_STAFF_SAMPLE_RATIO", "0.25"))
MIN_MAX_EXPANSION_OPEN_RIDES = int(os.environ.get("OPENRCT2_MIN_MAX_EXPANSION_OPEN_RIDES", "1"))
MIN_EXPANSION_OPEN_RIDE_SAMPLE_RATIO = float(os.environ.get("OPENRCT2_MIN_EXPANSION_OPEN_RIDE_SAMPLE_RATIO", "0.25"))
SEED_ONLY_NORM_CAP = float(os.environ.get("OPENRCT2_SEED_ONLY_NORM_CAP", "1.10"))
VERBOSE_OPERATION_DIAGNOSTICS = os.environ.get("OPENRCT2_VERBOSE_OPERATION_DIAGNOSTICS", "0") == "1"
MAX_ACTION_ERRORS_WITHOUT_PENALTY = int(os.environ.get("OPENRCT2_MAX_ACTION_ERRORS_WITHOUT_PENALTY", "10"))
RIDE_OPERATION_WEIGHT = float(os.environ.get("OPENRCT2_RIDE_OPERATION_WEIGHT", "0.0"))
OPEN_RIDE_OPERATION_WEIGHT = float(os.environ.get("OPENRCT2_OPEN_RIDE_OPERATION_WEIGHT", "0.60"))
STAFF_OPERATION_WEIGHT = float(os.environ.get("OPENRCT2_STAFF_OPERATION_WEIGHT", "0.40"))

MAX_PLUGIN_LOG_LINES = 40
MAX_PLUGIN_LOG_LEN = 240

MAX_STRING_FOLD_PASSES = 8


def fold_simple_string_concats(src):
    """Collapse adjacent quoted JS string literals joined with + for scanning."""
    pattern = re.compile(r"(['\"])([^'\"\\\n]*)\1\s*\+\s*(['\"])([^'\"\\\n]*)\3")
    folded = src
    for _ in range(MAX_STRING_FOLD_PASSES):
        next_folded = pattern.sub(lambda m: m.group(1) + m.group(2) + m.group(4) + m.group(1), folded)
        if next_folded == folded:
            break
        folded = next_folded
    return folded


def strip_js_comments(src):
    """Remove JS comments while preserving string literals and line structure."""
    out = []
    quote = None
    escape = False
    line_comment = False
    block_comment = False
    i = 0
    while i < len(src):
        ch = src[i]
        nxt = src[i + 1] if i + 1 < len(src) else ""

        if line_comment:
            if ch in "\n\r":
                line_comment = False
                out.append(ch)
            else:
                out.append(" ")
            i += 1
            continue

        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                out.append(" ")
                out.append(" ")
                i += 2
                continue
            out.append(ch if ch in "\n\r" else " ")
            i += 1
            continue

        if quote:
            out.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            i += 1
            continue

        if ch == "/" and nxt == "/":
            line_comment = True
            out.append(" ")
            out.append(" ")
            i += 2
            continue

        if ch == "/" and nxt == "*":
            block_comment = True
            out.append(" ")
            out.append(" ")
            i += 2
            continue

        if ch in "'\"":
            quote = ch
        out.append(ch)
        i += 1
    return "".join(out)


ALLOWED_ACTIONS = {
    "gamesetspeed",
    "ridesetprice",
    "ridesetstatus",
    "ridesetsetting",
    "ridesetname",
    "ridesetappearance",
    "ridesetcolourscheme",
    "ridecreate",
    "ridedemolish",
    "rideentranceexitplace",
    "rideentranceexitremove",
    "trackplace",
    "trackremove",
    "mazeplacetrack",
    "mazesettrack",
    "footpathplace",
    "footpathlayoutplace",
    "footpathremove",
    "footpathadditionplace",
    "footpathadditionremove",
    "parksetentrancefee",
    "parksetloan",
    "parkmarketing",
    "parksetresearchfunding",
    "parksetname",
    "staffhire",
    "stafffire",
    "staffsetname",
    "staffsetorders",
    "staffsetpatrolarea",
    "staffsetcostume",
    "landraise",
    "landlower",
    "landsetheight",
    "landsmooth",
    "landbuyrights",
    "landsetrights",
    "waterraise",
    "waterlower",
    "watersetheight",
    "clearscenery",
    "smallsceneryplace",
    "smallsceneryremove",
    "smallscenerysetcolour",
    "largesceneryplace",
    "largesceneryremove",
    "largescenerysetcolour",
    "wallplace",
    "wallremove",
    "wallsetcolour",
    "bannerplace",
    "bannerremove",
    "bannersetcolour",
    "bannersetname",
    "bannersetstyle",
    "parkentranceplace",
    "parkentranceremove",
}

SENSITIVE_STATE_FIELDS = (
    r"(?:companyValue|cash|bankLoan|rating|guests|entranceFee|"
    r"suggestedGuestMaximum|suggestedGuestCount|"
    r"happiness|happinessTarget|nausea|nauseaTarget|hunger|thirst|toilet|"
    r"energy|energyTarget|lostCountdown|status|inspectionInterval|"
    r"reliability|breakdownReason|lifecycleFlags|excitement|intensity|nauseaRating)"
)
GUEST_NEED_FIELDS = (
    r"(?:happiness|happinessTarget|nausea|nauseaTarget|hunger|thirst|toilet|"
    r"energy|energyTarget|lostCountdown)"
)
RIDE_MAINTENANCE_FIELDS = (
    r"(?:inspectionInterval|reliability|breakdownReason|lifecycleFlags|"
    r"excitement|intensity|nauseaRating)"
)
PLAIN_ASSIGN_OP = r"(?<![=!<>])=(?!=|>)"
ASSIGN_NO_UPDATE_OP = r"(?<![=!<>])[+\-*/%&|^]?=(?!=|>)"
ASSIGN_OP = r"(?<![=!<>])(?:[+\-*/%&|^]?=(?!=|>)|\+\+|--)"
FIELD_PLAIN_ASSIGN_OP = r"\s*" + PLAIN_ASSIGN_OP
FIELD_ASSIGN_NO_UPDATE_OP = r"\s*" + ASSIGN_NO_UPDATE_OP
FIELD_ASSIGN_OP = r"\s*" + ASSIGN_OP
PREFIX_UPDATE_OP = r"(?:\+\+|--)\s*"

FORBIDDEN_PATTERNS = [
    (r"\bEVAL_END\b", "submitted plugin must not control evaluation termination"),
    (r"__SEBENCH_MONITOR__", "submitted plugin must not spoof judge monitor markers"),
    (r"\b(?:park|date|scenario|climate|context|console|globalThis|window|this|map|network|objectManager|ui|pluginManager|titleSequenceManager|profiler|Object|Reflect|Function|Math|Number)\s*\[", "computed access to protected/runtime APIs is not allowed"),
    (r"\.\s*(?-i:constructor)\s*\(", "Function constructor/dynamic code construction is not allowed"),
    (r"\[\s*['\"]constructor['\"]\s*\]\s*\(", "Function constructor/dynamic code construction is not allowed"),
    (r"\.\s*(?:generateGuest|registerAction|executeLegacy|setFlag)\s*\(", "indirect forbidden API calls are not allowed"),
    (r"\[\s*['\"](?:generateGuest|registerAction|executeLegacy|setFlag|eval|Function|Proxy)['\"]\s*\]\s*\(", "indirect forbidden API calls are not allowed"),
    (r"\.\s*subscribe\s*\(\s*['\"](?!(?:interval\.tick|interval\.day)['\"])", "only interval.tick and interval.day subscriptions are allowed"),
    (r"\b[A-Za-z_$][\w$]*\s*=\s*context\s*\.\s*(?:executeAction|queryAction)\b\s*(?!\()", "aliasing action APIs is not allowed"),
    (r"\bcontext\s*\.\s*(?:executeAction|queryAction)\s*\.", "indirect action API invocation is not allowed"),
    (r"\.\s*" + SENSITIVE_STATE_FIELDS + FIELD_PLAIN_ASSIGN_OP, "direct sensitive game-state field assignment is not allowed"),
    (r"\b[A-Za-z_$][\w$]*\s*\[\s*['\"]" + SENSITIVE_STATE_FIELDS + r"['\"]\s*\]" + FIELD_PLAIN_ASSIGN_OP, "direct sensitive game-state field assignment is not allowed"),
    (r"\b[A-Za-z_$][\w$]*\s*\[[^\]]+\]\s*\.\s*" + SENSITIVE_STATE_FIELDS + FIELD_PLAIN_ASSIGN_OP, "direct array element game-state field assignment is not allowed"),
    (PREFIX_UPDATE_OP + r"(?:park|ride|guest|peep|staff|entity|date|scenario|climate)\s*(?:\.\s*" + SENSITIVE_STATE_FIELDS + r"|\[\s*['\"]" + SENSITIVE_STATE_FIELDS + r"['\"]\s*\])", "direct sensitive game-state field assignment is not allowed"),
    (r"\bconsole\s*(?:\.\s*log|\[\s*['\"]log['\"]\s*\])?" + FIELD_ASSIGN_OP, "submitted plugin must not replace judge logging APIs"),
    (r"\b(?:globalThis|window|this)\s*\.\s*console\s*(?:\.\s*log|\[\s*['\"]log['\"]\s*\])?" + FIELD_ASSIGN_OP, "submitted plugin must not replace judge logging APIs"),
    (r"(?-i:\bObject)\s*\.\s*(?-i:defineProperty)\s*\(", "runtime monkey-patching is not allowed"),
    (r"\b__define(?:Getter|Setter)__\s*\(", "runtime monkey-patching is not allowed"),
    (r"(?-i:\b(?:Number|isFinite))" + FIELD_ASSIGN_OP, "runtime monkey-patching is not allowed"),
    (r"\b(?:globalThis|window|this)\s*\.\s*(?-i:(?:Number|isFinite))" + FIELD_ASSIGN_OP, "runtime monkey-patching is not allowed"),
    (r"(?-i:\bMath)\s*\.\s*floor" + FIELD_ASSIGN_OP, "runtime monkey-patching is not allowed"),
    (r"(?-i:\bFunction)\s*\.\s*prototype\s*\.\s*(?:call|apply|bind)" + FIELD_ASSIGN_OP, "runtime monkey-patching is not allowed"),
    (r"\beval\s*\(", "dynamic code execution is not allowed"),
    (r"(?-i:\bFunction)\s*\(", "dynamic code execution is not allowed"),
    (r"(?-i:\bProxy)\s*\(", "runtime proxy hooks are not allowed"),
    (r"\bReflect\s*\.\s*set\s*\(", "runtime API mutation is not allowed"),
    (r"\bconsole\s*\.\s*executeLegacy\s*\(", "legacy console commands are not allowed"),
    (r"\bcontext\s*\.\s*registerAction\s*\(", "custom game actions are not allowed"),
    (r"\b(?:context|map|network|objectManager|ui|pluginManager|titleSequenceManager|profiler)\s*(?:\.\s*[A-Za-z_$][\w$]*|\[\s*['\"][^'\"]+['\"]\s*\])" + FIELD_ASSIGN_OP, "runtime API assignment is not allowed"),
    (r"\bcontext\s*\.\s*subscribe\s*\(\s*['\"](?!(?:interval\.tick|interval\.day)['\"])", "only interval.tick and interval.day subscriptions are allowed"),
    (r"\bcheats\b|\bcheatset\b", "cheat APIs are not allowed"),
    (r"\bgenerateGuest\s*\(", "direct guest generation is not allowed"),
    (r"\bpark\s*(?:\.\s*companyValue|\[\s*['\"]companyValue['\"]\s*\])" + FIELD_ASSIGN_OP, "direct companyValue assignment is not allowed"),
    (r"\bpark\s*(?:\.\s*value|\[\s*['\"]value['\"]\s*\])" + FIELD_ASSIGN_OP, "direct park value assignment is not allowed"),
    (r"\bpark\s*(?:\.\s*cash|\[\s*['\"]cash['\"]\s*\])" + FIELD_ASSIGN_OP, "direct cash assignment is not allowed"),
    (r"\bpark\s*(?:\.\s*bankLoan|\[\s*['\"]bankLoan['\"]\s*\])" + FIELD_ASSIGN_OP, "direct bankLoan assignment is not allowed"),
    (r"\bpark\s*(?:\.\s*rating|\[\s*['\"]rating['\"]\s*\])" + FIELD_ASSIGN_OP, "direct rating assignment is not allowed"),
    (r"\bpark\s*(?:\.\s*guests|\[\s*['\"]guests['\"]\s*\])" + FIELD_ASSIGN_OP, "direct guests assignment is not allowed"),
    (r"\bpark\s*(?:\.\s*entranceFee|\[\s*['\"]entranceFee['\"]\s*\])" + FIELD_ASSIGN_OP, "use parksetentrancefee action instead of direct entranceFee assignment"),
    (r"\b(?:date|scenario|climate)\s*(?:\.\s*[A-Za-z_$][\w$]*|\[\s*['\"][^'\"]+['\"]\s*\])" + FIELD_ASSIGN_OP, "direct date/scenario/climate mutation is not allowed"),
    (r"\bpark\s*\.\s*setFlag\s*\(", "direct park flag mutation is not allowed"),
    (r"\bpark\s*(?:\.\s*[A-Za-z_$][\w$]*|\[\s*['\"][^'\"]+['\"]\s*\])" + FIELD_ASSIGN_OP, "direct park property assignment is not allowed"),
    (r"\b(?:ride|guest|peep|staff|entity)\s*\.\s*[A-Za-z_$][\w$]*" + FIELD_ASSIGN_OP, "direct ride/guest/peep/staff/entity field assignment is not allowed"),
    (r"\b(?:ride|guest|peep|staff|entity)\s*\[\s*['\"][^'\"]+['\"]\s*\]" + FIELD_ASSIGN_OP, "direct ride/guest/peep/staff/entity field assignment is not allowed"),
    (r"\bmap\s*\.\s*get(?:Entity|Ride)\s*\([^)]*\)\s*\.\s*[A-Za-z_$][\w$]*" + FIELD_ASSIGN_OP, "direct map entity/ride field assignment is not allowed"),
    (r"\bmap\s*\.\s*rides\s*\[[^\]]+\]\s*\.\s*[A-Za-z_$][\w$]*" + FIELD_ASSIGN_OP, "direct map ride field assignment is not allowed"),
    (r"\bmap\s*\.\s*getAllEntities\s*\([^)]*\)\s*\[[^\]]+\]\s*\.\s*[A-Za-z_$][\w$]*" + FIELD_ASSIGN_OP, "direct map entity field assignment is not allowed"),
    (PREFIX_UPDATE_OP + r"map\s*\.\s*(?:get(?:Entity|Ride)\s*\([^)]*\)|rides\s*\[[^\]]+\]|getAllEntities\s*\([^)]*\)\s*\[[^\]]+\])\s*\.\s*[A-Za-z_$][\w$]*", "direct map entity/ride field assignment is not allowed"),
    (r"\bcontext\s*\.\s*research\s*(?:\.\s*[A-Za-z_$][\w$]*|\[\s*['\"][^'\"]+['\"]\s*\])" + FIELD_ASSIGN_OP, "use parksetresearchfunding action instead of direct research assignment"),
    (r"\b(?:parksetdate|parksetparameter|scenariosetsetting|guestsetflags|peepspawnplace|ridefreezerating)\b", "scenario parameter/date, rating-freeze, and direct peep/guest manipulation actions are not allowed"),
    (r"\bsoftcap\b|park\s*\.\s*guest\s*\.\s*softcap", "guest soft-cap hooks are not allowed"),
    (r"\bpark\s*(?:\.\s*suggestedGuest(?:Maximum|Count)|\[\s*['\"]suggestedGuest(?:Maximum|Count)['\"]\s*\])" + FIELD_ASSIGN_OP, "modifying suggested guest counts is not allowed"),
    (r"guest\s*\.\s*generation", "guest generation hooks are not allowed"),
    (r"\.\s*" + GUEST_NEED_FIELDS + FIELD_PLAIN_ASSIGN_OP, "direct guest need/mood assignment is not allowed"),
    (r"\.\s*" + RIDE_MAINTENANCE_FIELDS + FIELD_PLAIN_ASSIGN_OP, "direct ride maintenance/rating assignment is not allowed"),
    (r"\b(?:guest|peep|entity)[A-Za-z0-9_$]*\s*(?:\.\s*cash|\[\s*['\"]cash['\"]\s*\])" + FIELD_PLAIN_ASSIGN_OP, "direct guest cash assignment is not allowed"),
    (r"\b\w+\s*\[[^\]]+\]\s*(?:\.\s*cash|\[\s*['\"]cash['\"]\s*\])" + FIELD_PLAIN_ASSIGN_OP, "direct entity cash assignment is not allowed"),
    (r"\.\s*setFlag\s*\(\s*['\"](?:lost|hunger|toilet|nausea|angry|leavingPark)['\"]", "direct guest flag manipulation is not allowed"),
]


def find_matching_paren(src, open_pos):
    depth = 0
    quote = None
    escape = False
    line_comment = False
    block_comment = False
    for i in range(open_pos, len(src)):
        ch = src[i]
        nxt = src[i + 1] if i + 1 < len(src) else ""
        if line_comment:
            if ch in "\n\r":
                line_comment = False
            continue
        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
            continue
        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            continue
        if ch == "/" and nxt == "/":
            line_comment = True
            continue
        if ch == "/" and nxt == "*":
            block_comment = True
            continue
        if ch in "'\"":
            quote = ch
            continue
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
    return -1


def first_argument(src, open_pos):
    end = find_matching_paren(src, open_pos)
    if end < 0:
        return None
    depth = 0
    quote = None
    escape = False
    line_comment = False
    block_comment = False
    start = open_pos + 1
    for i in range(start, end):
        ch = src[i]
        nxt = src[i + 1] if i + 1 < len(src) else ""
        if line_comment:
            if ch in "\n\r":
                line_comment = False
            continue
        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
            continue
        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            continue
        if ch == "/" and nxt == "/":
            line_comment = True
            continue
        if ch == "/" and nxt == "*":
            block_comment = True
            continue
        if ch in "'\"":
            quote = ch
            continue
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            if depth > 0:
                depth -= 1
        elif ch == "," and depth == 0:
            return src[start:i].strip()
    return src[start:end].strip()


def plain_js_string_literal_value(expr):
    expr = expr.strip()
    if len(expr) < 2 or expr[0] not in "'\"" or expr[-1] != expr[0]:
        return None
    quote = expr[0]
    body = expr[1:-1]
    # Action names are ASCII identifiers; escapes and embedded quotes close unicode/hex or concat bypasses.
    if quote in body or "\\" in body or "\n" in body or "\r" in body:
        return None
    return body


def find_action_wrappers(src):
    wrappers = {}
    skip_spans = []
    patterns = [
        re.compile(r"\bvar\s+(?P<name>[A-Za-z_$][\w$]*)\s*=\s*function\s*\(\s*(?P<param>[A-Za-z_$][\w$]*)\s*,[^)]*\)\s*\{\s*context\s*\.\s*(?P<method>executeAction|queryAction)\s*\(\s*(?P=param)\s*,", re.S),
        re.compile(r"\bfunction\s+(?P<name>[A-Za-z_$][\w$]*)\s*\(\s*(?P<param>[A-Za-z_$][\w$]*)\s*,[^)]*\)\s*\{\s*context\s*\.\s*(?P<method>executeAction|queryAction)\s*\(\s*(?P=param)\s*,", re.S),
    ]
    for pattern in patterns:
        for m in pattern.finditer(src):
            wrappers[m.group("name")] = m.group("method")
            call_start = src.find("context", m.start(), m.end())
            if call_start >= 0:
                skip_spans.append((call_start, m.end()))
    return wrappers, skip_spans


def in_spans(pos, spans):
    return any(start <= pos < end for start, end in spans)


def is_function_declaration_reference(src, pos):
    prefix = src[max(0, pos - 20):pos]
    return re.search(r"function\s+$", prefix) is not None


def validate_action_calls(src):
    violations = []
    wrappers, skip_spans = find_action_wrappers(src)
    direct_re = re.compile(r"(?:(?P<object>\b[A-Za-z_$][\w$]*)\s*\.\s*)?(?P<method>executeAction|queryAction)\s*\(")
    for m in direct_re.finditer(src):
        if in_spans(m.start(), skip_spans):
            continue
        obj = m.group("object")
        if obj != "context":
            violations.append("action API calls must use context.executeAction/queryAction directly")
            continue
        action_name = plain_js_string_literal_value(first_argument(src, m.end() - 1) or "")
        if action_name is None:
            violations.append("action name must be a plain string literal from the allowlist")
        elif action_name not in ALLOWED_ACTIONS:
            violations.append("action '%s' is not in the allowed action list" % action_name)

    for wrapper in wrappers:
        wrapper_re = re.compile(r"(?<![\w$.])" + re.escape(wrapper) + r"\s*\(")
        for m in wrapper_re.finditer(src):
            if is_function_declaration_reference(src, m.start()):
                continue
            action_name = plain_js_string_literal_value(first_argument(src, m.end() - 1) or "")
            if action_name is None:
                violations.append("wrapped action name must be a plain string literal from the allowlist")
            elif action_name not in ALLOWED_ACTIONS:
                violations.append("wrapped action '%s' is not in the allowed action list" % action_name)
    return violations


def validate_plugin(plugin_path):
    with open(plugin_path, encoding="utf-8") as f:
        src = f.read()
    code_src = strip_js_comments(src)
    scan_sources = [code_src]
    folded = fold_simple_string_concats(code_src)
    if folded != code_src:
        scan_sources.append(folded)
    violations = []
    seen = set()
    for scan_src in scan_sources:
        for pattern, message in FORBIDDEN_PATTERNS:
            if message not in seen and re.search(pattern, scan_src, flags=re.IGNORECASE):
                violations.append(message)
                seen.add(message)
        for message in validate_action_calls(scan_src):
            if message not in seen:
                violations.append(message)
                seen.add(message)
    return violations


def clear_plugin_dir():
    os.makedirs(PLUGIN_DIR, exist_ok=True)
    for name in os.listdir(PLUGIN_DIR):
        if name.endswith(".js"):
            try:
                os.remove(os.path.join(PLUGIN_DIR, name))
            except OSError:
                pass


def write_monitor(token):
    monitor_path = os.path.join(PLUGIN_DIR, "00_sebench_monitor.js")
    monitor_src = """
(function() {
    var token = \"__TOKEN__\";
    var safeLog = console.log.bind(console);
    var days = 0;
    var ticks = 0;
    var done = false;
    var targetDays = 992;
    var initialRideIds = {};
    var seedRideIds = {};
    var seedReady = false;
    var seedFailed = false;
    var seedBuilding = false;

    function rememberInitialRides() {
        var rides = map.rides;
        for (var i = 0; i < rides.length; i++) {
            if (rides[i]) initialRideIds[rides[i].id] = true;
        }
    }

    function currentValue() {
        var v = park.companyValue;
        if (v !== v || v < 0) return 0;
        if (v > 2147483647) return 2147483647;
        return v | 0;
    }

    function safeInt(v) {
        if (v === undefined || v === null || v !== v) return 0;
        if (v > 2147483647) return 2147483647;
        if (v < -2147483648) return -2147483648;
        return v | 0;
    }

    function countOpenRides() {
        var n = 0;
        var rides = map.rides;
        for (var i = 0; i < rides.length; i++) {
            if (rides[i] && rides[i].status === "open") n++;
        }
        return n;
    }

    function countStaff() {
        try {
            return map.getAllEntities("staff").length | 0;
        } catch (e) {
            return 0;
        }
    }

    function surfaceOwned(elements) {
        for (var i = 0; i < elements.length; i++) {
            var el = elements[i];
            if (el.type === "surface") {
                return !!(el.hasOwnership || el.ownership >= 2);
            }
        }
        return false;
    }

    function buildBlocked(elements) {
        for (var i = 0; i < elements.length; i++) {
            var el = elements[i];
            if (el.type === "track" || el.type === "entrance" ||
                el.type === "large_scenery" || el.type === "wall") {
                return true;
            }
        }
        return false;
    }

    function findSeedSpots() {
        var spots = [];
        var seen = {};
        var dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];
        var sz = map.size;
        for (var px = 1; px < sz.x - 1; px++) {
            for (var py = 1; py < sz.y - 1; py++) {
                var ptile = map.getTile(px, py);
                var pelems = ptile.elements;
                if (!pelems || !surfaceOwned(pelems)) continue;
                for (var i = 0; i < pelems.length; i++) {
                    var pel = pelems[i];
                    if (pel.type !== "footpath") continue;
                    for (var d = 0; d < dirs.length; d++) {
                        var sx = px + dirs[d][0];
                        var sy = py + dirs[d][1];
                        if (sx < 5 || sy < 5 || sx >= sz.x - 5 || sy >= sz.y - 5) continue;
                        var key = sx + "," + sy + "," + pel.baseZ;
                        if (seen[key]) continue;
                        var stile = map.getTile(sx, sy);
                        var selems = stile.elements;
                        if (!selems || !surfaceOwned(selems) || buildBlocked(selems)) continue;
                        seen[key] = true;
                        spots.push({ sx: sx, sy: sy, z: pel.baseZ });
                    }
                }
            }
        }
        return spots;
    }

    function findSeedEntries() {
        var entries = [];
        var seen = {};
        var preferredTypes = [25, 33, 46, 49, 71, 81, 69, 39];
        for (var p = 0; p < preferredTypes.length; p++) {
            for (var slot = 0; slot < 256; slot++) {
                try {
                    var obj = context.getObject("ride", slot);
                    if (!obj || !obj.rideType || obj.rideType[0] !== preferredTypes[p]) continue;
                    if (obj.shopItem !== 255) continue;
                    if (obj.minCarsInTrain !== 1 || obj.maxCarsInTrain !== 1) continue;
                    if (obj.zeroCars !== 0) continue;
                    if (seen[slot]) continue;
                    seen[slot] = true;
                    entries.push({
                        rideType: obj.rideType[0],
                        rideObject: slot,
                        name: obj.name
                    });
                } catch (e) {
                }
            }
        }
        return entries;
    }

    function placeSeedEntranceExit(rideId, sx, sy, cb) {
        var positions = [
            { x: sx - 1, y: sy }, { x: sx + 1, y: sy },
            { x: sx, y: sy - 1 }, { x: sx, y: sy + 1 },
            { x: sx - 1, y: sy - 1 }, { x: sx + 1, y: sy + 1 },
            { x: sx - 1, y: sy + 1 }, { x: sx + 1, y: sy - 1 }
        ];
        function tryOne(isExit, start, used, doneOne) {
            var idx = start;
            function stepPosition() {
                if (idx >= positions.length) {
                    doneOne(null);
                    return;
                }
                var pos = positions[idx++];
                if (used && pos.x === used.x && pos.y === used.y) {
                    stepPosition();
                    return;
                }
                var dir = 0;
                function stepDirection() {
                    if (dir > 3) {
                        stepPosition();
                        return;
                    }
                    var args = {
                        x: pos.x * 32,
                        y: pos.y * 32,
                        direction: dir++,
                        ride: rideId,
                        station: 0,
                        isExit: isExit
                    };
                    context.queryAction("rideentranceexitplace", args, function(q) {
                        if (q.error !== 0) {
                            stepDirection();
                            return;
                        }
                        context.executeAction("rideentranceexitplace", args, function(e) {
                            if (e.error === 0) {
                                doneOne(pos);
                            } else {
                                stepDirection();
                            }
                        });
                    });
                }
                stepDirection();
            }
            stepPosition();
        }
        tryOne(false, 0, null, function(entrance) {
            if (!entrance) {
                cb(false);
                return;
            }
            tryOne(true, 0, entrance, function(exit) {
                cb(!!exit);
            });
        });
    }

    function countManagedOpenRides() {
        if (!seedReady) return 0;
        var n = 0;
        var rides = map.rides;
        for (var i = 0; i < rides.length; i++) {
            var ride = rides[i];
            if (!ride || ride.status !== "open") continue;
            if (seedRideIds[ride.id] || !initialRideIds[ride.id]) n++;
        }
        return n;
    }

    function countExpansionOpenRides() {
        if (!seedReady) return 0;
        var n = 0;
        var rides = map.rides;
        for (var i = 0; i < rides.length; i++) {
            var ride = rides[i];
            if (!ride || ride.status !== "open") continue;
            if (!seedRideIds[ride.id] && !initialRideIds[ride.id]) n++;
        }
        return n;
    }

    function countExpansionRides() {
        if (!seedReady) return 0;
        var n = 0;
        var rides = map.rides;
        for (var i = 0; i < rides.length; i++) {
            var ride = rides[i];
            if (!ride) continue;
            if (!seedRideIds[ride.id] && !initialRideIds[ride.id]) n++;
        }
        return n;
    }

    function countSeedRides() {
        var n = 0;
        for (var k in seedRideIds) {
            if (seedRideIds.hasOwnProperty(k)) n++;
        }
        return n;
    }

    function trySeedBuild(seeds, seedIndex, spots, spotIndex) {
        if (seedReady || seedFailed) return;
        if (seedIndex >= seeds.length) {
            seedFailed = true;
            return;
        }
        if (spotIndex >= spots.length || spotIndex >= 120) {
            trySeedBuild(seeds, seedIndex + 1, spots, 0);
            return;
        }
        var seed = seeds[seedIndex];
        var spot = spots[spotIndex];
        context.executeAction("ridecreate", {
            rideType: seed.rideType,
            rideObject: seed.rideObject,
            entranceObject: 0,
            colour1: 0,
            colour2: 0,
            inspectionInterval: 2
        }, function(created) {
            if (created.error !== 0 || created.ride === undefined) {
                trySeedBuild(seeds, seedIndex, spots, spotIndex + 1);
                return;
            }
            var rideId = created.ride;
            function fail(nextSeed) {
                context.executeAction("ridedemolish", { ride: rideId, modifyType: 0 }, function() {
                    if (nextSeed) {
                        trySeedBuild(seeds, seedIndex + 1, spots, 0);
                    } else {
                        trySeedBuild(seeds, seedIndex, spots, spotIndex + 1);
                    }
                });
            }
            function tryTrackDirection(direction) {
                if (direction > 3) {
                    fail(false);
                    return;
                }
                context.executeAction("trackplace", {
                    x: spot.sx * 32,
                    y: spot.sy * 32,
                    z: spot.z,
                    direction: direction,
                    ride: rideId,
                    trackType: 2,
                    rideType: seed.rideType,
                    brakeSpeed: 0,
                    colour: 0,
                    seatRotation: 0,
                    trackPlaceFlags: 0,
                    isFromTrackDesign: false
                }, function(placed) {
                    if (placed.error !== 0) {
                        tryTrackDirection(direction + 1);
                        return;
                    }
                    placeSeedEntranceExit(rideId, spot.sx, spot.sy, function(okEntranceExit) {
                        if (!okEntranceExit) {
                            fail(false);
                            return;
                        }
                        context.queryAction("ridesetstatus", { ride: rideId, status: 1 }, function(openCheck) {
                            if (openCheck.error === 0) {
                                context.executeAction("ridesetstatus", { ride: rideId, status: 1 }, function(opened) {
                                    if (opened.error !== 0) {
                                        fail(false);
                                        return;
                                    }
                                    context.executeAction("ridesetstatus", { ride: rideId, status: 0 }, function(closed) {
                                        if (closed.error !== 0) {
                                            fail(false);
                                            return;
                                        }
                                        seedRideIds[rideId] = true;
                                        seedReady = true;
                                        context.executeAction("ridesetprice", {
                                            ride: rideId,
                                            price: 20,
                                            isPrimaryPrice: true
                                        });
                                    });
                                });
                            } else {
                                var msg = String(openCheck.errorMessage || "");
                                fail(msg.indexOf("vehicles") >= 0);
                            }
                        });
                    });
                });
            }
            tryTrackDirection(0);
        });
    }

    function ensureSeed() {
        if (seedReady || seedFailed || seedBuilding) return;
        seedBuilding = true;
        var seeds = findSeedEntries();
        var spots = findSeedSpots();
        if (!seeds.length || !spots.length) {
            seedFailed = true;
            return;
        }
        trySeedBuild(seeds, 0, spots, 0);
    }

    function emit(kind) {
        safeLog(\"__SEBENCH_MONITOR__\" + token + \":\" + kind +
                \":value=\" + currentValue() +
                \":date=\" + date.year + \",\" + date.month + \",\" + date.day +
                \":rating=\" + safeInt(park.rating) +
                \":guests=\" + safeInt(park.guests) +
                \":cash=\" + safeInt(park.cash) +
                \":loan=\" + safeInt(park.bankLoan) +
                \":rides=\" + safeInt(map.rides.length) +
                \":openRides=\" + countOpenRides() +
                \":managedOpenRides=\" + countManagedOpenRides() +
                \":expansionRides=\" + countExpansionRides() +
                \":expansionOpenRides=\" + countExpansionOpenRides() +
                \":seedReady=\" + (seedReady ? 1 : 0) +
                \":seedFailed=\" + (seedFailed ? 1 : 0) +
                \":seedRides=\" + countSeedRides() +
                \":staff=\" + countStaff() +
                \":end=1");
    }

    function finish() {
        if (done) return;
        done = true;
        emit(\"DONE\");
    }

    var main = function() {
        if (context.mode !== \"normal\") return;
        rememberInitialRides();
        context.executeAction(\"gamesetspeed\", {speed: 4});
        context.subscribe(\"interval.tick\", function() {
            ticks++;
            if (!seedReady && !seedFailed) ensureSeed();
            if ((seedReady || seedFailed) && ticks % 1024 === 0) emit(\"SCORE\");
        });
        context.subscribe(\"interval.day\", function() {
            days++;
            if (!seedReady && !seedFailed) ensureSeed();
            if ((seedReady || seedFailed) && days % 14 === 0) emit(\"SCORE\");
            if (days >= targetDays) finish();
        });
    };

    registerPlugin({
        name: \"SEBenchJudgeMonitor\",
        version: \"1.0\",
        authors: [\"sebench\"],
        type: \"remote\",
        licence: \"MIT\",
        targetApiVersion: 34,
        main: main
    });
})();
""".replace("__TOKEN__", token)
    with open(monitor_path, "w", encoding="utf-8") as f:
        f.write(monitor_src)
    return monitor_path


def parse_monitor_payload(payload):
    fields = {}
    for part in payload.strip().split(":"):
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        fields[key] = value
    return fields


def int_field(fields, key, default=0):
    try:
        match = re.match(r"\s*(-?[\d,]+)", str(fields.get(key, default)))
        if not match:
            return default
        return int(match.group(1).replace(",", ""))
    except (TypeError, ValueError):
        return default


def trim_plugin_log(line):
    line = line.rstrip("\n\r")
    if not line:
        return None
    if len(line) > MAX_PLUGIN_LOG_LEN:
        line = line[:MAX_PLUGIN_LOG_LEN] + "...[truncated]"
    return line


def is_action_error_line(line):
    return (
        "ERROR[" in line
        or "ERROR:" in line
        or "Can't " in line
        or "Unavailable" in line
        or "failed" in line.lower()
        or "invalid" in line.lower()
    )


def print_scenario_diagnostics(basename, first_fields, last_fields, samples,
                               max_rides, max_open_rides, max_guests,
                               max_staff, max_managed_open_rides,
                               max_expansion_rides, max_expansion_open_rides,
                               ride_samples, open_ride_samples,
                               managed_open_ride_samples,
                               expansion_ride_samples,
                               expansion_open_ride_samples, staff_samples,
                               seed_ready_samples, seed_failed,
                               action_errors, plugin_logs):
    if last_fields:
        start_value = int_field(first_fields or {}, "value")
        final_value = int_field(last_fields, "value")
        print(
            "  [%s] judge diagnostics: start companyValue %s, final companyValue %s, "
            "cash %s, loan %s, rides %s, openRides %s, managedOpenRides %s, "
            "staff %s, guests %s, rating %s, seedReady %s, seedFailed %s, samples %s"
            % (
                basename,
                "{:,}".format(start_value),
                "{:,}".format(final_value),
                "{:,}".format(int_field(last_fields, "cash")),
                "{:,}".format(int_field(last_fields, "loan")),
                int_field(last_fields, "rides"),
                int_field(last_fields, "openRides"),
                int_field(last_fields, "managedOpenRides"),
                int_field(last_fields, "staff"),
                int_field(last_fields, "guests"),
                int_field(last_fields, "rating"),
                int_field(last_fields, "seedReady"),
                seed_failed,
                samples,
            )
        )
        print(
            "  [%s] judge maxima: rides %s, openRides %s, managedOpenRides %s, staff %s, guests %s, actionErrors %s"
            % (basename, max_rides, max_open_rides, max_managed_open_rides, max_staff, max_guests, action_errors)
        )
        print(
            "  [%s] judge expansion: expansionRides %s, expansionOpenRides %s"
            % (basename, max_expansion_rides, max_expansion_open_rides)
        )
        if VERBOSE_OPERATION_DIAGNOSTICS:
            print(
                "  [%s] judge operation: rideSamples %s/%s, openRideSamples %s/%s, "
                "managedOpenRideSamples %s/%s, expansionRideSamples %s/%s, "
                "expansionOpenRideSamples %s/%s, staffSamples %s/%s, "
                "seedReadySamples %s/%s"
                % (
                    basename,
                    ride_samples,
                    samples,
                    open_ride_samples,
                    samples,
                    managed_open_ride_samples,
                    samples,
                    expansion_ride_samples,
                    samples,
                    expansion_open_ride_samples,
                    samples,
                    staff_samples,
                    samples,
                    seed_ready_samples,
                    samples,
                )
            )
        else:
            print(
                "  [%s] judge operation: rideActivity %s, openRideActivity %s, managedOpenRideActivity %s, expansionActivity %s, staffActivity %s"
                % (
                    basename,
                    "yes" if ride_samples else "no",
                    "yes" if open_ride_samples else "no",
                    "yes" if managed_open_ride_samples else "no",
                    "yes" if expansion_open_ride_samples else "no",
                    "yes" if staff_samples else "no",
                )
            )
    else:
        print("  [%s] judge diagnostics: no hidden-monitor samples observed" % basename)

    if plugin_logs:
        print("  [%s] untrusted plugin log sample:" % basename)
        for line in plugin_logs[:MAX_PLUGIN_LOG_LINES]:
            print("    " + line)


def run_scenario(scenario_path, plugin_path, timeout):
    """Run one scenario and return the last judge-monitor company value."""
    clear_plugin_dir()
    token = secrets.token_hex(16)
    write_monitor(token)

    dest = os.path.join(PLUGIN_DIR, "zz_submitted_plugin.js")

    with open(plugin_path, encoding="utf-8") as f:
        src = f.read()
    with open(dest, "w", encoding="utf-8") as f:
        f.write(src)

    monitor_re = re.compile(
        r"__SEBENCH_MONITOR__%s:(SCORE|DONE):(.*)" % re.escape(token)
    )

    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = OPENRCT2_DIR + ":" + env.get("LD_LIBRARY_PATH", "")

    cmd = [
        OPENRCT2_CLI,
        "host", scenario_path,
        "--headless",
        "--openrct2-data-path=" + DATA_PATH,
    ]

    basename = os.path.basename(scenario_path)
    print("  [%s] starting (timeout=%ds)" % (basename, timeout))

    final_value = 0
    first_fields = None
    last_fields = None
    samples = 0
    max_rides = 0
    max_open_rides = 0
    max_managed_open_rides = 0
    max_expansion_rides = 0
    max_expansion_open_rides = 0
    max_staff = 0
    max_guests = 0
    ride_samples = 0
    open_ride_samples = 0
    managed_open_ride_samples = 0
    expansion_ride_samples = 0
    expansion_open_ride_samples = 0
    staff_samples = 0
    seed_ready_samples = 0
    seed_failed = 0
    action_errors = 0
    plugin_logs = []
    proc = None
    selector = None
    try:
        proc = subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            env=env, text=True, bufsize=1,
        )
        selector = selectors.DefaultSelector()
        selector.register(proc.stdout, selectors.EVENT_READ)
        t0 = time.time()

        while time.time() - t0 <= timeout:
            if proc.poll() is not None:
                break

            events = selector.select(timeout=1.0)
            if not events:
                continue

            line = proc.stdout.readline()
            if not line:
                continue

            m = monitor_re.search(line)
            if m:
                fields = parse_monitor_payload(m.group(2))
                if first_fields is None:
                    first_fields = dict(fields)
                last_fields = dict(fields)
                samples += 1
                final_value = int_field(fields, "value")
                rides_now = int_field(fields, "rides")
                open_rides_now = int_field(fields, "openRides")
                managed_open_rides_now = int_field(fields, "managedOpenRides")
                expansion_rides_now = int_field(fields, "expansionRides")
                expansion_open_rides_now = int_field(fields, "expansionOpenRides")
                staff_now = int_field(fields, "staff")
                seed_ready_now = int_field(fields, "seedReady")
                max_rides = max(max_rides, rides_now)
                max_open_rides = max(max_open_rides, open_rides_now)
                max_managed_open_rides = max(max_managed_open_rides, managed_open_rides_now)
                max_expansion_rides = max(max_expansion_rides, expansion_rides_now)
                max_expansion_open_rides = max(max_expansion_open_rides, expansion_open_rides_now)
                max_staff = max(max_staff, staff_now)
                max_guests = max(max_guests, int_field(fields, "guests"))
                seed_failed = max(seed_failed, int_field(fields, "seedFailed"))
                if rides_now >= MIN_MAX_RIDES:
                    ride_samples += 1
                if open_rides_now >= MIN_MAX_OPEN_RIDES:
                    open_ride_samples += 1
                if managed_open_rides_now >= MIN_MAX_OPEN_RIDES:
                    managed_open_ride_samples += 1
                if expansion_rides_now >= 1:
                    expansion_ride_samples += 1
                if expansion_open_rides_now >= MIN_MAX_EXPANSION_OPEN_RIDES:
                    expansion_open_ride_samples += 1
                if staff_now >= MIN_MAX_STAFF:
                    staff_samples += 1
                if seed_ready_now:
                    seed_ready_samples += 1
                if m.group(1) == "DONE":
                    break
            else:
                trimmed = trim_plugin_log(line)
                if trimmed is not None:
                    if samples > 0 and is_action_error_line(trimmed):
                        action_errors += 1
                    if len(plugin_logs) < MAX_PLUGIN_LOG_LINES:
                        plugin_logs.append(trimmed)

        if proc.poll() is None:
            proc.send_signal(signal.SIGTERM)
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=5)
    except Exception as exc:
        print("  [%s] error: %s" % (basename, exc))
        if proc is not None:
            try:
                proc.kill()
            except Exception:
                pass
    finally:
        if selector is not None:
            selector.close()
        clear_plugin_dir()

    print_scenario_diagnostics(
        basename, first_fields, last_fields, samples, max_rides,
        max_open_rides, max_guests, max_staff, max_managed_open_rides,
        max_expansion_rides, max_expansion_open_rides,
        ride_samples, open_ride_samples, managed_open_ride_samples,
        expansion_ride_samples,
        expansion_open_ride_samples,
        staff_samples, seed_ready_samples, seed_failed, action_errors, plugin_logs,
    )
    print("  [%s] final company value = %s" % (basename, "{:,}".format(final_value)))
    return {
        "value": final_value,
        "max_rides": max_rides,
        "max_open_rides": max_open_rides,
        "max_managed_open_rides": max_managed_open_rides,
        "max_expansion_rides": max_expansion_rides,
        "max_expansion_open_rides": max_expansion_open_rides,
        "max_staff": max_staff,
        "max_guests": max_guests,
        "total_samples": samples,
        "ride_samples": ride_samples,
        "open_ride_samples": open_ride_samples,
        "managed_open_ride_samples": managed_open_ride_samples,
        "expansion_ride_samples": expansion_ride_samples,
        "expansion_open_ride_samples": expansion_open_ride_samples,
        "staff_samples": staff_samples,
        "seed_ready_samples": seed_ready_samples,
        "seed_failed": seed_failed,
        "action_errors": action_errors,
    }


def bounded_ratio(value, target):
    if target <= 0:
        return 1.0
    return max(0.0, min(1.0, value / float(target)))


def operation_multiplier(metrics, managed_open_ride_ratio, staff_ratio):
    """Scale value score by real operation, preserving the original score scale."""
    total_weight = OPEN_RIDE_OPERATION_WEIGHT + STAFF_OPERATION_WEIGHT
    if total_weight <= 0:
        return 0.0

    score = 0.0
    if metrics["max_managed_open_rides"] >= MIN_MAX_OPEN_RIDES:
        score += OPEN_RIDE_OPERATION_WEIGHT * bounded_ratio(
            managed_open_ride_ratio, MIN_OPEN_RIDE_SAMPLE_RATIO
        )
    if metrics["max_staff"] >= MIN_MAX_STAFF:
        score += STAFF_OPERATION_WEIGHT * bounded_ratio(staff_ratio, MIN_STAFF_SAMPLE_RATIO)
    return max(0.0, min(1.0, score / float(total_weight)))


def has_effective_expansion(metrics, expansion_open_ride_ratio):
    return (
        metrics.get("max_expansion_open_rides", 0) >= MIN_MAX_EXPANSION_OPEN_RIDES
        and expansion_open_ride_ratio >= MIN_EXPANSION_OPEN_RIDE_SAMPLE_RATIO
    )


def expansion_feedback(metrics):
    if metrics.get("max_expansion_open_rides", 0) >= MIN_MAX_EXPANSION_OPEN_RIDES:
        return "expansion open but not sustained"
    if metrics.get("max_expansion_rides", 0) > 0:
        return "expansion created but not open"
    return "expansion missing"


def score_scenario(filename, metrics):
    value = metrics["value"]
    baseline = BASELINES.get(filename, 1)
    raw_norm = value / baseline if baseline else 0.0
    reason = "value ratio %.4f" % raw_norm

    total_samples = max(1, metrics.get("total_samples", 0))
    managed_open_ride_ratio = metrics.get("managed_open_ride_samples", 0) / float(total_samples)
    expansion_open_ride_ratio = metrics.get("expansion_open_ride_samples", 0) / float(total_samples)
    staff_ratio = metrics.get("staff_samples", 0) / float(total_samples)
    multiplier = operation_multiplier(metrics, managed_open_ride_ratio, staff_ratio)
    if metrics.get("seed_ready_samples", 0) <= 0:
        multiplier = 0.0
    norm = raw_norm * multiplier

    operation_failures = []
    if metrics.get("seed_ready_samples", 0) <= 0:
        operation_failures.append("setup")
    if metrics["max_managed_open_rides"] < MIN_MAX_OPEN_RIDES or managed_open_ride_ratio < MIN_OPEN_RIDE_SAMPLE_RATIO:
        operation_failures.append("openrides")
    if metrics["max_staff"] < MIN_MAX_STAFF or staff_ratio < MIN_STAFF_SAMPLE_RATIO:
        operation_failures.append("staff")
    if operation_failures:
        if VERBOSE_OPERATION_DIAGNOSTICS:
            reason = (
                "operation gate failed: " + "; ".join(operation_failures) +
                "; operation multiplier %.3f from ratios managed open rides %.3f, staff %.3f"
                % (multiplier, managed_open_ride_ratio, staff_ratio)
            )
        else:
            reason = "operation gate failed: " + "; ".join(operation_failures)
        if multiplier > 0:
            reason += "; partial operation multiplier applied"

    expansion_ok = has_effective_expansion(metrics, expansion_open_ride_ratio)
    expansion_reason = expansion_feedback(metrics)
    if not expansion_ok and (not operation_failures or "setup" not in operation_failures):
        if norm > SEED_ONLY_NORM_CAP:
            norm = SEED_ONLY_NORM_CAP
            reason += "; score capped: " + expansion_reason
        else:
            reason += "; " + expansion_reason

    action_errors = metrics["action_errors"]
    if action_errors > MAX_ACTION_ERRORS_WITHOUT_PENALTY:
        excess = action_errors - MAX_ACTION_ERRORS_WITHOUT_PENALTY
        penalty = max(0.50, 1.0 - 0.02 * excess)
        norm *= penalty
        if VERBOSE_OPERATION_DIAGNOSTICS:
            reason += "; action error penalty %.2f for %s errors" % (penalty, action_errors)
        else:
            reason += "; noisy action execution penalty applied"

    if not operation_failures and multiplier < 1.0:
        reason += "; partial operation multiplier applied"

    return min(norm, 2.0), reason


def evaluate(plugin_path, scenarios_dir, timeout):
    violations = validate_plugin(plugin_path)
    if violations:
        print("Submission rejected by anti-cheat checks. Cheating or attempted cheating receives zero score.")
        return 0.0

    results = []
    for filename in sorted(os.listdir(scenarios_dir)):
        if not filename.endswith(".park"):
            continue
        path = os.path.join(scenarios_dir, filename)
        metrics = run_scenario(path, plugin_path, timeout)
        value = metrics["value"]
        baseline = BASELINES.get(filename, 1)
        norm, score_reason = score_scenario(filename, metrics)
        results.append({"scenario": filename, "value": value,
                         "baseline": baseline, "norm": norm})
        print("  [%s] scoring: %s" % (filename, score_reason))
        print("  [%s] normalized = %.4f" % (filename, norm))

    if not results:
        print("No scenarios found!")
        return 0.0

    avg = sum(r["norm"] for r in results) / len(results)
    print("\n" + "=" * 50)
    print(" Average normalized score: %.4f" % avg)
    print("=" * 50)
    return avg


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("plugin", help="Path to AI plugin .js file")
    ap.add_argument("--timeout", type=int, default=120,
                    help="Wall-clock seconds per scenario (default 120)")
    ap.add_argument("--scenarios-dir",
                    default=os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                         "scenarios"),
                    help="Directory containing .park scenario files")
    args = ap.parse_args()

    if not os.path.isfile(args.plugin):
        sys.exit("Plugin not found: " + args.plugin)
    if not os.path.isfile(OPENRCT2_CLI):
        sys.exit("OpenRCT2 CLI not found: " + OPENRCT2_CLI)

    score = evaluate(args.plugin, args.scenarios_dir, args.timeout)
    print("Final score: %.4f" % score)


if __name__ == "__main__":
    main()
