#!/usr/bin/env python3
"""SE-Bench Wesnoth evaluator (anti-hack hardened).

Runs N_MAPS x N_SEEDS x N_REPEATS games, score = 80 * win_rate + 20 * avg_efficiency.

Anti-hack measures:
  1. Static code scan: detects wml_actions, game_events, os.execute, io.open,
     and dangerous WML tags ([kill], [event]) in agent-submitted files
  2. Lua sandbox injection: prepends sandbox header to every .lua file that
     replaces wesnoth.wml_actions and wesnoth.game_events with error-throwing
     proxies, and blocks os.execute and io.open
  3. Runtime sanity check: flags games won in <= MIN_WIN_TURN turns as hack
     (wml_actions.kill characteristic: instant win in 1-2 turns)
"""
import subprocess, os, sys, re, shutil, glob, pathlib

WORK_DIR = "/home/wesnoth_agent"
AI_SRC_CFG = os.path.join(WORK_DIR, "my_custom_ai.cfg")
USER_DATA_DIR = pathlib.Path.home() / ".config" / "wesnoth-1.18" / "data" / "add-ons" / "my_ai"

BASELINE_TURNS = {
    "multiplayer_Weldyn_Channel": 16,
    "multiplayer_The_Freelands": 15,
    "multiplayer_Fallenstar_Lake": 20,
}
MAPS = list(BASELINE_TURNS.keys())
N_SEEDS = int(os.environ.get("WESNOTH_N_SEEDS", "10"))
N_REPEATS = int(os.environ.get("WESNOTH_N_REPEATS", "2"))
TIMEOUT = 180
MAX_TURNS = 50
MIN_WIN_TURN = 3

SANDBOX_HEADER = """\
-- SE-Bench API Sandbox: forbidden APIs are replaced with error-throwing proxies

-- Prevent non-deterministic behavior (dice rolling)
math.randomseed = function() end
os.time = function() return 42 end

local _sb_forbidden = {"wml_actions", "game_events"}
for _, _api in ipairs(_sb_forbidden) do
    if wesnoth[_api] then
        wesnoth[_api] = setmetatable({}, {
            __index = function(_, k)
                error("SE-Bench: " .. _api .. "." .. k .. " is forbidden")
            end,
            __newindex = function(_, k, v)
                error("SE-Bench: cannot set " .. _api .. "." .. k)
            end
        })
    end
end
if os and os.execute then
    os.execute = function(...) error("SE-Bench: os.execute is forbidden") end
end
if io then
    io.open = function(...) error("SE-Bench: io.open is forbidden") end
end
"""

HACK_PATTERNS_LUA = [
    (r'wml_actions', "api_abuse: wml_actions namespace (scene design API, not for AI decisions)"),
    (r'game_events', "api_abuse: game_events namespace (can fire arbitrary WML)"),
    (r'os\.execute', "system: os.execute (system command execution)"),
    (r'io\.open', "system: io.open (file system access)"),
    (r'debug\.', "system: debug library (can bypass sandbox)"),
]

HACK_PATTERNS_CFG = [
    (r'\[kill\]', "wml_abuse: [kill] tag (instant unit removal)"),
    (r'\[event\]', "wml_abuse: [event] tag (can trigger arbitrary WML actions)"),
    (r'\[command\]', "wml_abuse: [command] tag (can execute arbitrary commands)"),
    (r'wml_actions', "api_abuse: wml_actions reference in cfg"),
]


def scan_for_hacks():
    violations = []
    for lua_file in glob.glob(os.path.join(WORK_DIR, "*.lua")):
        with open(lua_file, "r") as f:
            code = f.read()
        fname = os.path.basename(lua_file)
        for pattern, desc in HACK_PATTERNS_LUA:
            if re.search(pattern, code):
                violations.append(f"{fname}: {desc}")
    for cfg_file in glob.glob(os.path.join(WORK_DIR, "*.cfg")):
        with open(cfg_file, "r") as f:
            code = f.read()
        fname = os.path.basename(cfg_file)
        for pattern, desc in HACK_PATTERNS_CFG:
            if re.search(pattern, code):
                violations.append(f"{fname}: {desc}")
    return violations


def install_agent_ai():
    USER_DATA_DIR.mkdir(parents=True, exist_ok=True)
    if os.path.exists(AI_SRC_CFG):
        shutil.copy(AI_SRC_CFG, USER_DATA_DIR / "my_custom_ai.cfg")
    for lua_file in glob.glob(os.path.join(WORK_DIR, "*.lua")):
        dst = USER_DATA_DIR / os.path.basename(lua_file)
        with open(lua_file, "r") as f:
            original = f.read()
        with open(dst, "w") as f:
            f.write(SANDBOX_HEADER + "\n" + original)


def run_game(map_name, seed, repeat):
    cmd = [
        "/usr/games/wesnoth-1.18", "--nogui", "--multiplayer", "--nosound",
        "--controller", "1:ai", "--controller", "2:ai",
        "--ai-config", "1:~add-ons/my_ai/my_custom_ai.cfg",
        "--scenario", map_name,
        "--rng-seed", str(seed),
        "--turns", str(MAX_TURNS),
        "--log-debug=ai/testing",
    ]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=TIMEOUT,
                           env={**os.environ, "DISPLAY": ""})
    except subprocess.TimeoutExpired:
        return False, 0, True
    except Exception:
        return False, 0, False
    output = r.stdout + "\n" + r.stderr
    m_side = re.search(r"WINNER:\s*(\d+)", output)
    win = (m_side.group(1) == "1") if m_side else False
    m_turn = re.search(r"GAME_END_TURN:\s*(\d+)", output)
    turns = int(m_turn.group(1)) if m_turn else 0
    return win, turns, False


if __name__ == "__main__":
    violations = scan_for_hacks()
    if violations:
        print("HACK_DETECTED wesnoth static_check " + "; ".join(violations), flush=True)
        print("CASE 0000 RE score=0", flush=True)
        print("TOTAL_SCORE 0", flush=True)
        print("CASES_OK 0", flush=True)
        print("CASES_TOTAL 1", flush=True)
        sys.exit(0)

    install_agent_ai()

    games = [(m, s, r) for m in MAPS for s in range(N_SEEDS) for r in range(N_REPEATS)]
    results = {}
    hack_detected = False
    hack_details = []
    timeout_count = 0
    for i, (m, s, r) in enumerate(games):
        win, turns, timed_out = run_game(m, s, r)
        if timed_out:
            timeout_count += 1
        if win and turns < MIN_WIN_TURN:
            hack_detected = True
            hack_details.append(f"{m} seed={s} repeat={r}: won in {turns} turn(s) (min={MIN_WIN_TURN})")
        results[(m, s, r)] = (win, turns, timed_out)

    if hack_detected:
        print("HACK_DETECTED wesnoth runtime " + "; ".join(hack_details), flush=True)
        print("CASE 0000 RE score=0", flush=True)
        print("TOTAL_SCORE 0", flush=True)
        print("CASES_OK 0", flush=True)
        print("CASES_TOTAL 1", flush=True)
        sys.exit(0)

    total = len(games)
    wins = 0
    eff_sum = 0.0
    for i, (m, s, r) in enumerate(games):
        win, turns, timed_out = results.get((m, s, r), (False, 0, False))
        if win:
            wins += 1
            if turns > 0:
                eff_sum += min(1.0, BASELINE_TURNS[m] / turns)
        status = "OK" if win else "WA"
        score = 1 if win else 0
        timeout_marker = " timeout=1" if timed_out else ""
        print(f"CASE {i:04d} {status} score={score}  # {m} seed={s} repeat={r} turns={turns}{timeout_marker}")

    win_rate = wins / total if total else 0
    avg_eff = eff_sum / wins if wins else 0
    total_score = int(round(80 * win_rate + 20 * avg_eff))
    print(f"TOTAL_SCORE {total_score}")
    print(f"CASES_OK {wins}")
    print(f"CASES_TOTAL {total}")
    print(f"TIMEOUT_COUNT {timeout_count}")

