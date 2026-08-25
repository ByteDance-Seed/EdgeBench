# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Script generators for agent execution.

Produces bash scripts that run inside the work container:
- sforge-submit: submits current code to judge server via HTTP, prints results,
  updates shared state file (display-only cache)

Agent-specific scripts (stop hooks, settings files) live in the corresponding
agent modules under ``sforge.harness.agent``.

State file `/tmp/sforge_state.json` (display-only, not used for final scoring):
  {
    "best_pass_rate":  float,
    "best_score":      float|null,
    "best_round":      str,   # "agent-N" or "auto-N"
    "submissions": [
      {"kind": "agent"|"auto", "round": str, "at": int, "pass_rate": float, "score": float|null}
    ]
  }
"""

from __future__ import annotations


def generate_submit_script() -> str:
    """Generate the sforge-submit bash script.

    Submits via POST to the token-based endpoint and polls for results.
    The server manages task_id, run_id, and round counters.

    Flags:
      --details, -d    submit and show detailed per-test results
      --list, -l       list all previous submissions (no new submission)
    """
    return _generate_submit_script()


def _generate_submit_script() -> str:
    """Generate sforge-submit: token-based POST + poll until result is ready."""
    return r"""#!/bin/bash
set -e

LIST_MODE=0
DETAILS_MODE=0
for arg in "$@"; do
    case "$arg" in
        --list|-l) LIST_MODE=1 ;;
        --details|-d) DETAILS_MODE=1 ;;
        -h|--help)
            echo "Usage: sforge-submit [OPTIONS]"
            echo ""
            echo "Submit current code to the judge server for evaluation."
            echo "Results include score, pass rate, and a summary of findings."
            echo ""
            echo "Options:"
            echo "  --list, -l      List all previous submissions and scores for this run"
            echo "  --details, -d   Submit and show detailed per-test results (triggers a new submission)"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $arg" >&2
            echo "Run 'sforge-submit --help' for usage." >&2
            exit 1
            ;;
    esac
done

JUDGE_URL="${SFORGE_JUDGE_URL}"
TOKEN="${SFORGE_TOKEN}"
PATCH_DIR="${SFORGE_PATCH_DIR:-$(pwd)}"
STATE_FILE="/tmp/sforge_state.json"

if [ -z "$JUDGE_URL" ]; then
    echo "ERROR: SFORGE_JUDGE_URL not set" >&2
    exit 1
fi
if [ -z "$TOKEN" ]; then
    echo "ERROR: SFORGE_TOKEN not set" >&2
    exit 1
fi

if [ "$LIST_MODE" -eq 1 ]; then
    HIST=$(curl -s -m 30 "$JUDGE_URL/api/v1/history?token=$TOKEN")
    if [ -z "$HIST" ]; then
        echo "ERROR: No response from judge server" >&2
        exit 1
    fi
    BEST_RATE=$(echo "$HIST" | jq -r '.best_pass_rate // 0')
    BEST_SCORE=$(echo "$HIST" | jq -r '.best_score // "N/A"')
    COUNT=$(echo "$HIST" | jq -r '.entries | length')
    echo ""
    echo "========================================"
    echo "  Submission History"
    echo "  Total submissions: $COUNT"
    echo "  Best pass rate: $(jq -n --argjson r "$BEST_RATE" '$r * 100 | . * 10 | floor / 10')%"
    if [ "$BEST_SCORE" != "N/A" ] && [ "$BEST_SCORE" != "null" ]; then
        echo "  Best score: $BEST_SCORE"
    fi
    echo "========================================"
    echo ""
    if [ "$COUNT" -gt 0 ]; then
        printf "  %-14s %-10s %-8s %-12s %-10s %s\n" "ROUND" "STATUS" "VALID" "PASS_RATE" "SCORE" "SUMMARY"
        printf "  %-14s %-10s %-8s %-12s %-10s %s\n" "-----" "------" "-----" "---------" "-----" "-------"
        echo "$HIST" | jq -r '.entries[] | select(.type == "submission") |
            "  " +
            ((.round // "-") | . + " " * ([14 - length, 0] | max)) + " " +
            ((.status // "-") | . + " " * ([10 - length, 0] | max)) + " " +
            (if .valid == false then "no" else "yes" end | . + " " * ([8 - length, 0] | max)) + " " +
            (if .pass_rate != null then (.pass_rate * 100 * 10 | floor / 10 | tostring + "%") else "-" end | . + " " * ([12 - length, 0] | max)) + " " +
            (if .score != null then (.score | tostring) else "-" end | . + " " * ([10 - length, 0] | max)) + " " +
            ((.summary // "-") | if length > 40 then .[:37] + "..." else . end)'
    fi
    echo ""
    exit 0
fi

# ── Archive ──

cd "$PATCH_DIR"
ARCHIVE_FILE=$(mktemp --suffix=.tar.gz)
TAR_PATHS="${SFORGE_SUBMIT_PATHS:-.}"
if [ -n "${SFORGE_SUBMIT_PATHS:-}" ]; then
    EXISTING_PATHS=""
    for p in $SFORGE_SUBMIT_PATHS; do
        [ -e "$p" ] && EXISTING_PATHS="$EXISTING_PATHS $p"
    done
    TAR_PATHS="${EXISTING_PATHS# }"
fi
if [ -z "$TAR_PATHS" ]; then
    tar czf "$ARCHIVE_FILE" --files-from /dev/null
else
    tar czf "$ARCHIVE_FILE" --exclude='.git' ${SFORGE_SUBMIT_EXCLUDE_FLAGS:-} $TAR_PATHS
fi
ARCHIVE_SIZE=$(wc -c < "$ARCHIVE_FILE")

echo ""
echo "========================================"
echo "  Submitting for evaluation"
echo "  Archive size: $ARCHIVE_SIZE bytes"
echo "  Waiting for test results..."
echo "========================================"
echo ""

# ── Submit + poll ──

HTTP_CODE=$(curl -s -o /tmp/_submit_resp.json -w '%{http_code}' -m 120 -X POST "$JUDGE_URL/api/v1/submit" \
    -F "token=$TOKEN" \
    -F "archive=@$ARCHIVE_FILE")
rm -f "$ARCHIVE_FILE"
SUBMIT_RESP=$(cat /tmp/_submit_resp.json)

if [ "$HTTP_CODE" = "429" ]; then
    DETAIL=$(echo "$SUBMIT_RESP" | jq -r '.detail // empty')
    if echo "$DETAIL" | grep -qi "budget\|exhausted"; then
        echo "SUBMISSION LIMIT REACHED: $DETAIL" >&2
        echo "$DETAIL"
    else
        echo "COOLDOWN: $DETAIL" >&2
        echo "$DETAIL"
    fi
    exit 1
fi

SUBMISSION_ID=$(echo "$SUBMIT_RESP" | jq -r '.submission_id // empty')
ROUND_ID=$(echo "$SUBMIT_RESP" | jq -r '.round_id // empty')
REMAINING=$(echo "$SUBMIT_RESP" | jq -r '.remaining_submissions // empty')
if [ -z "$SUBMISSION_ID" ]; then
    echo "ERROR: Failed to submit to judge server (HTTP $HTTP_CODE)" >&2
    echo "$SUBMIT_RESP" >&2
    exit 1
fi

if [ -n "$ROUND_ID" ]; then
    if [ -n "$REMAINING" ] && [ "$REMAINING" != "null" ]; then
        echo "  Round: $ROUND_ID  (remaining submissions: $REMAINING)"
    else
        echo "  Round: $ROUND_ID"
    fi
    echo ""
fi

for _ in $(seq 1 720); do
    sleep 10
    RESULT=$(curl -s -m 30 "$JUDGE_URL/api/v1/result/$SUBMISSION_ID" 2>/dev/null || true)
    STATUS=$(echo "$RESULT" | jq -r '.status // empty')
    if [ "$STATUS" = "completed" ] || [ "$STATUS" = "error" ]; then
        break
    fi
done

STATUS=$(echo "$RESULT" | jq -r '.status // empty')
if [ "$STATUS" != "completed" ] && [ "$STATUS" != "error" ]; then
    echo "ERROR: Evaluation timed out or judge unreachable" >&2
    exit 1
fi

# ── Parse + update display cache + print ──

TS=$(date +%s)
ERROR_MSG=$(echo "$RESULT" | jq -r '.error // empty')

if [ -n "$ERROR_MSG" ]; then
    CURRENT_RATE=0
    CURRENT_SCORE="null"
    PASSED=0
    TOTAL=0
    FAILED=0
else
    REPORT=$(echo "$RESULT" | jq -r '.report')
    PASSED=$(echo "$REPORT" | jq -r '.passed')
    TOTAL=$(echo "$REPORT" | jq -r '.total_tests')
    FAILED=$(echo "$REPORT" | jq -r '.failed')
    CURRENT_RATE=$(echo "$REPORT" | jq -r '.pass_rate')
    CURRENT_SCORE=$(echo "$REPORT" | jq -r '.score // null')
    VALID=$(echo "$REPORT" | jq -r '.valid // true')
    SUMMARY=$(echo "$REPORT" | jq -r '.summary // empty')
fi

# Update local state file (display-only cache — not used for final scoring)
if [ ! -f "$STATE_FILE" ]; then
    echo '{"best_pass_rate": 0, "best_score": null, "best_round": "", "submissions": []}' > "$STATE_FILE"
fi
TMP=$(mktemp)
jq --arg round "${ROUND_ID:-unknown}" \
   --argjson ts "$TS" \
   --argjson rate "$CURRENT_RATE" \
   --argjson score "$CURRENT_SCORE" \
   '
   .submissions += [{kind: "agent", round: $round, at: $ts, pass_rate: $rate, score: $score}]
   | if $rate > (.best_pass_rate // 0) then
       .best_pass_rate = $rate | .best_round = $round | .best_score = $score
     else . end
   ' "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"

if [ -n "$ERROR_MSG" ]; then
    echo "========================================"
    echo "  ${ROUND_ID:-submission}: ERROR"
    echo "  $ERROR_MSG"
    echo "========================================"
else
    echo "========================================"
    echo "  ${ROUND_ID:-submission} Results"
    echo "========================================"
    if [ "$VALID" = "false" ]; then
        echo "  Valid:       no"
    fi
    if [ "$CURRENT_SCORE" != "null" ]; then
        echo "  Score:       $CURRENT_SCORE"
    fi
    if [ "$TOTAL" -gt 0 ] 2>/dev/null; then
        PASS_PCT=$(jq -n --argjson r "$CURRENT_RATE" '$r * 100 | . * 10 | floor / 10')
        echo "  Pass rate:   ${PASS_PCT}%"
        echo "  Passed:      $PASSED/$TOTAL"
    fi
    if [ -n "$SUMMARY" ]; then
        echo ""
        echo "  Summary:"
        echo "    $SUMMARY"
    fi
    # Show metrics if present
    METRICS=$(echo "$REPORT" | jq -r '.metrics // empty')
    if [ -n "$METRICS" ] && [ "$METRICS" != "{}" ] && [ "$METRICS" != "null" ]; then
        echo ""
        echo "  Metrics:"
        echo "$REPORT" | jq -r '.metrics | to_entries[] | "    \(.key): \(.value)"'
    fi
    echo ""
    # Show failed items (from details if available, else from test_details)
    DETAIL_FAILURES=$(echo "$REPORT" | jq -r '[.details[]? | select(.status != "PASSED")] | length')
    if [ "$DETAIL_FAILURES" -gt 0 ] 2>/dev/null; then
        echo "  Failed checks:"
        echo "$REPORT" | jq -r '.details[] | select(.status != "PASSED") | .name' | head -20 | while read -r t; do echo "    - $t"; done
        if [ "$DETAIL_FAILURES" -gt 20 ] 2>/dev/null; then
            echo "    ... and $((DETAIL_FAILURES - 20)) more"
        fi
    else
        FAILED_TESTS=$(echo "$REPORT" | jq -r '.test_details[]? | select(.status != "PASSED") | .name')
        if [ -n "$FAILED_TESTS" ]; then
            echo "  Failed tests:"
            echo "$FAILED_TESTS" | head -20 | while read -r t; do echo "    - $t"; done
        else
            if [ "$TOTAL" -gt 0 ] 2>/dev/null; then
                echo "  All tests passed!"
            fi
        fi
    fi
    # Show full details if --details flag
    if [ "$DETAILS_MODE" -eq 1 ]; then
        HAS_DETAILS=$(echo "$REPORT" | jq -r '.details | length')
        if [ "$HAS_DETAILS" -gt 0 ] 2>/dev/null; then
            echo ""
            echo "  Details:"
            echo "$REPORT" | jq -r '.details[] | "    [\(.status)] \(.name)\(if .message then ": " + .message else "" end)"'
        fi
    fi
    echo "========================================"
    echo ""
fi
"""


def generate_evolve_prompt(
    original_query: str,
    submit_paths: list[str] | None = None,
    internet: bool = True,
    max_submissions: int | None = None,
    submission_cooldown: int | None = None,
) -> str:
    """Generate the enhanced prompt wrapping the task query with eval instructions."""
    submit_files_note = ""
    if submit_paths:
        paths_str = ", ".join(f"`{p}`" for p in submit_paths)
        submit_files_note = (
            f"\n### Submitted Files\n\n"
            f"Only the following paths are submitted for evaluation: {paths_str}\n\n"
            f"**Keep these files in a compilable/runnable state at all times.** "
            f"A background process periodically auto-evaluates your code — if the "
            f"submitted files are broken, incomplete, or contain syntax errors at "
            f"that moment, the auto-evaluation will fail. Write changes to disk "
            f"promptly and ensure the submitted files always represent your current "
            f"best solution.\n"
        )

    network_note = ""
    if not internet:
        network_note = (
            "\n### Network Environment\n\n"
            "**This environment has NO internet access.** "
            "Only the judge server and the AI API are reachable. "
            "Do not attempt to download packages, fetch remote resources, "
            "or access external URLs — all dependencies are pre-installed "
            "in the workspace.\n"
        )

    budget_note = ""
    if max_submissions is not None or submission_cooldown is not None:
        parts = []
        if max_submissions is not None:
            parts.append(
                f"- You have a **limited number of submissions ({max_submissions} total)**. "
                f"Plan carefully and validate locally before submitting."
            )
        if submission_cooldown is not None:
            parts.append(
                f"- There is a **minimum interval of {submission_cooldown}s** between submissions."
            )
        budget_note = "\n### Submission Limits\n\n" + "\n".join(parts) + "\n"

    how_to_test = (
        "### How to Test Your Code\n\n"
        "- Run `sforge-submit` to submit your current code for evaluation. "
        "It will package the files, send them to the judge server, and return "
        "results showing score, pass rate, and a summary of findings.\n"
        "- Run `sforge-submit --details` to submit and see detailed per-test results.\n"
        "- Run `sforge-submit --list` to view all previous submissions and "
        "their scores for this run.\n\n"
        "You should use these regularly to check your progress and identify issues.\n"
    )

    return (
        "## Iterative Evaluation Mode\n\n"
        "You are working with iterative test feedback. "
        "After implementing code, you can submit your work for evaluation at any "
        "time to see which tests pass and which fail, then iterate based on the results.\n\n"
        f"{how_to_test}"
        f"{submit_files_note}"
        f"{budget_note}"
        f"{network_note}\n"
        "### Strategy\n\n"
        "- **Implement incrementally**: Complete one module/project at a time\n"
        "- **Read test feedback carefully**: Failed test names often hint at what's broken\n"
        "- **Iterate**: Fix failing tests based on the feedback, then submit again\n\n"
        "### Scoring\n\n"
        "- Your **best score** across all submissions is your final score\n"
        "- You don't lose points for failed attempts — experimentation is encouraged\n\n"
        "---\n\n"
        f"{original_query}\n"
    )


def generate_game_prompt(original_query: str, internet: bool = True) -> str:
    """Generate the enhanced prompt for game mode.

    Wraps the task-specific query with common game interaction instructions
    (HTTP API docs, tips, keypress handling, rules, scoring). When `internet`
    is False, also tells the agent that walkthrough lookups are blocked, so
    it doesn't waste turns on failing web fetches.
    """
    network_note = ""
    if not internet:
        network_note = (
            "## Network Environment\n\n"
            "**This environment has NO internet access.** Only the game server "
            "(`GAME_SERVER_URL`) and the AI API are reachable; everything else "
            "is iptables-blocked. **Do not** attempt to search the web, fetch "
            "walkthroughs, or download external resources — those calls will "
            "time out and waste your turns. Solve the game through gameplay.\n\n"
            "---\n\n"
        )

    return (
        "## Game Mode\n\n"
        "You are playing an **interactive fiction game** via an HTTP API. "
        "Send commands to the game server and maximize your score.\n\n"
        "---\n\n"
        f"{network_note}"
        "## Game Server HTTP API\n\n"
        "The server URL is available in the `GAME_SERVER_URL` environment variable.\n\n"
        "### Start a new game\n"
        "```\n"
        "POST {GAME_SERVER_URL}/new\n"
        "Body: {}\n"
        'Response: {"session_id": "abc123", "observation": "...", "score": 0, '
        '"peak_score": 0, "max_score": 350, "done": false, "moves": 0}\n'
        "```\n\n"
        "### Take an action\n"
        "```\n"
        "POST {GAME_SERVER_URL}/{session_id}/step\n"
        'Body: {"action": "go north"}\n'
        'Response: {"session_id": "...", "observation": "...", "score": 5, '
        '"peak_score": 5, "max_score": 350, "done": false, "moves": 1}\n'
        "```\n\n"
        "### Check status\n"
        "```\n"
        "GET {GAME_SERVER_URL}/{session_id}/status\n"
        'Response: {"session_id": "...", "score": 5, "peak_score": 5, '
        '"max_score": 350, "done": false, "moves": 1}\n'
        "```\n\n"
        "### Close session\n"
        "```\n"
        "POST {GAME_SERVER_URL}/{session_id}/close\n"
        'Response: {"session_id": "...", "final_score": 5, "peak_score": 5, '
        '"max_score": 350, "moves": 50}\n'
        "```\n\n"
        "### Score fields\n"
        "- `score` — the score you currently have in this session.\n"
        "- `peak_score` — the highest score you reached so far in this session "
        "(useful in games where score can decrease).\n"
        "- `max_score` — the theoretical maximum score for the game (constant). "
        "Your goal is to get `score` as close to `max_score` as possible.\n\n"
        "---\n\n"
        "## Tips\n\n"
        "- Interactive fiction games accept natural language commands: "
        '"go north", "take lamp", "examine door", "open mailbox", "read leaflet", etc.\n'
        "- `look` describes the current room. Moving in a direction that doesn't exist gives a failure message.\n"
        "- The game has puzzles — read descriptions carefully and experiment.\n"
        "- You can start multiple game sessions to explore different strategies.\n"
        "- **Keypress prompts**: Some games pause with prompts like "
        '`(Press SPACE to Continue)` or `[press BACKSPACE to return to game]`. '
        "When you see these in the observation, send a **single space** `\" \"` as "
        "the next action to dismiss them. These are Z-machine interactive prompts "
        "that require a single-character response, not a regular text command.\n\n"
        "---\n\n"
        "## Environment\n\n"
        "- `GAME_SERVER_URL` environment variable is pre-set.\n"
        "- Use `curl`, `urllib.request`, or `http.client` for HTTP requests.\n"
        "- Python 3.10 stdlib is available.\n\n"
        "---\n\n"
        "## Rules\n\n"
        "- All game interaction must go through the HTTP API.\n"
        "- You may start multiple game sessions to explore.\n"
        "- Maximize your score across all sessions.\n\n"
        "## Scoring\n\n"
        "- Your **best score** across all game sessions is your final result, "
        "normalized against `max_score` (the game's theoretical maximum).\n"
        "- You don't lose points for failed sessions — experimentation is encouraged.\n\n"
        "---\n\n"
        f"{original_query}\n"
    )
