#!/usr/bin/env python3
"""DCSS holdout evaluator. Fixed but agent-hidden seeds, wizard-mode auto-zero.

The seed pool here is the HOLDOUT — agents should NOT see, log, or memorize
these values. The CASE lines emitted intentionally omit seed information so
the agent only learns ordinal indices.
"""
import glob, json, os, re, subprocess, threading, time, shutil

CRAWL_BIN = "/usr/games/crawl"
GAME_DIR = "/opt/tiger/game/DCSS"
MORGUE_DIR = os.path.join(GAME_DIR, "morgue")
WORK_DIR = "/home/dcss_agent"
# Hidden holdout. Big random ints — not enumerable, not greppable from common docs.
HOLDOUT_SEEDS = [3452561731, 3551582249, 3574227031, 3842641307, 3675221201]
TIMEOUT = int(os.environ.get("DCSS_TIMEOUT", "900"))
MAX_TURNS = int(os.environ.get("DCSS_MAX_TURNS", "100000"))

WIZARD_RE = re.compile(r"Entered (wizard|explore) mode|WIZARD|EX-WIZARD")

def _stuff(session, keys):
    subprocess.run(f"screen -S {session} -X stuff {keys}",
                   shell=True, executable="/bin/bash", capture_output=True, timeout=5)

def _stuff_raw(session, escape_seq):
    # screen's `eval 'stuff \\NNN'` lets us send raw bytes like Esc (\033), Ctrl+Q (\021), CR (\015)
    subprocess.run(f"screen -S {session} -X eval 'stuff {escape_seq}'",
                   shell=True, executable="/bin/bash", capture_output=True, timeout=5)

def _suicide(session):
    # Force-end the game and write a morgue from any state.
    # Sequence:
    #   * Ctrl+G opens the autotravel prompt — this forcibly interrupts any
    #     continuous action (autoexplore, autofight, autorest) and returns to
    #     the command-input layer.
    #   * Esc x2 cancels the autotravel prompt + any other menu, back at the
    #     bare "command" prompt.
    #   * Ctrl+Q opens the "Are you sure you want to abandon this character?"
    #     prompt.
    #   * Literal "yes" + Enter confirms, crawl writes morgue.
    with open(f"/tmp/_suicide_{session}.log", "a") as logf:
        logf.write(f"{time.time():.1f} suicide start\n")
        # Clear --more-- prompts and close menus before sending Ctrl+Q.
        for _ in range(12):
            _stuff(session, "' '")
            time.sleep(0.2)
        for _ in range(8):
            _stuff_raw(session, r"\033")
            time.sleep(0.15)
        _stuff_raw(session, r"\007")   # Ctrl+G (BEL) — interrupt continuous action
        time.sleep(0.6)
        for _ in range(8):
            _stuff_raw(session, r"\033")
            time.sleep(0.25)
        _stuff_raw(session, r"\021")   # Ctrl+Q
        time.sleep(2.0)
        _stuff_raw(session, r"\025")   # Ctrl+U clears any bot-typed prompt input
        time.sleep(0.2)
        _stuff(session, "'yes'")
        time.sleep(0.6)
        _stuff_raw(session, r"\015")   # Enter
        time.sleep(0.5)
        # capture screen for debug
        subprocess.run(f"screen -S {session} -X hardcopy /tmp/_suicide_{session}_scr.txt",
                       shell=True, executable="/bin/bash", capture_output=True, timeout=5)
        logf.write(f"{time.time():.1f} suicide end\n")

def _dismiss_loop(session, stop):
    keys = ["' '", "' '", "' '", "$'\\r'", "' '", "' '", "$'\\e'"]
    i = 0
    while not stop.is_set():
        try: _stuff(session, keys[i % len(keys)])
        except: pass
        i += 1
        stop.wait(1.5)

def _alive(session):
    return subprocess.run(f"screen -list 2>/dev/null | grep -q {session}",
                          shell=True).returncode == 0

def extract_morgue_score(path):
    try:
        text = open(path).read()
        if WIZARD_RE.search(text):
            return None, "banned-mode"
        lines = text.splitlines()
        if len(lines) >= 5:
            m = re.match(r"^\s*(\d+)\s+", lines[4])
            if m: return int(m.group(1)), None
    except: pass
    return None, "no-score"

def run_game(seed, idx, rc_file):
    name = f"Eval{idx}"
    session = f"dcss_{idx}_{os.getpid()}"
    done_flag = f"/tmp/dcss_done_{idx}_{os.getpid()}"
    if os.path.exists(done_flag): os.remove(done_flag)
    # Each parallel game gets an isolated crawl dir; morgues stay shared.
    game_dir = os.path.join(GAME_DIR, f"game_{idx}")
    shutil.rmtree(game_dir, ignore_errors=True)
    os.makedirs(game_dir, exist_ok=True)
    for pattern in ["*.rc", "*.lua"]:
        for f in glob.glob(os.path.join(WORK_DIR, pattern)):
            try: shutil.copy(f, os.path.join(game_dir, os.path.basename(f)))
            except: pass
    subprocess.run(f"screen -S {session} -X quit", shell=True, capture_output=True)
    time.sleep(0.3)

    existing = set(glob.glob(os.path.join(MORGUE_DIR, f"morgue-{name}-*.txt")))
    wrapper_rc = os.path.join(game_dir, f"_wrap_{idx}.rc")
    with open(wrapper_rc, "w") as f:
        f.write(f": MAX_TURNS = {MAX_TURNS}\n")
        f.write(open(rc_file).read())

    cmd = (f"{CRAWL_BIN} -name {name} -species Mi -background Be -seed {seed} -extra-opt-last weapon=mace"
           f" -rc {wrapper_rc} -rcdir {game_dir} -morgue {MORGUE_DIR} -dir {game_dir}")
    subprocess.run(f"screen -dmS {session} bash -lc 'stty -ixon; {cmd} 2>/dev/null; echo DONE > {done_flag}'",
                   shell=True)
    time.sleep(5)
    _stuff(session, "$'\\n'"); time.sleep(1)
    _stuff(session, "$'\\n'"); time.sleep(1)
    _stuff(session, "'#'"); time.sleep(1)
    _stuff(session, "'+'"); time.sleep(2)
    for _ in range(5): _stuff(session, "' '"); time.sleep(0.2)

    stop = threading.Event()
    t = threading.Thread(target=_dismiss_loop, args=(session, stop), daemon=True); t.start()

    t0 = time.time()
    suicided = False
    hard_timeout = TIMEOUT + 90
    while True:
        elapsed = time.time() - t0
        if elapsed > hard_timeout:
            subprocess.run(f"pkill -f 'crawl.*-name {name}'", shell=True, capture_output=True)
            time.sleep(2); break
        if os.path.exists(done_flag): os.remove(done_flag); break
        if not _alive(session): break
        # Gracefully abandon before the wall-time deadline so crawl writes a morgue.
        # Stop dismiss_loop first so its space keys don't fight the suicide prompt.
        if not suicided and elapsed > TIMEOUT:
            suicided = True
            stop.set()
            time.sleep(3.0)   # let dismiss_loop fully stop
            _suicide(session)
            # Wait until either morgue is produced (crawl exits) or hard timeout
            wait_t0 = time.time()
            while time.time() - wait_t0 < 18:
                if os.path.exists(done_flag) or not _alive(session): break
                time.sleep(1)
            # one retry if still alive
            if _alive(session):
                _suicide(session)
                time.sleep(4)
        time.sleep(1)
    stop.set(); t.join(timeout=3); time.sleep(1)
    _stuff(session, "$'\\r'"); time.sleep(1)
    subprocess.run(f"screen -S {session} -X quit", shell=True, capture_output=True)

    current = set(glob.glob(os.path.join(MORGUE_DIR, f"morgue-{name}-*.txt")))
    new_morgues = current - existing
    if new_morgues:
        mf = max(new_morgues, key=os.path.getmtime)
        sc, err = extract_morgue_score(mf)
        if sc is not None: return ("OK", sc)
    return ("WA", 0)

def main():
    os.makedirs(MORGUE_DIR, exist_ok=True)
    # wipe any old morgues to avoid cross-submission contamination
    for f in glob.glob(os.path.join(MORGUE_DIR, "morgue-*")): 
        try: os.remove(f)
        except: pass
    for pattern in ["*.rc", "*.lua"]:
        for f in glob.glob(os.path.join(WORK_DIR, pattern)):
            shutil.copy(f, os.path.join(GAME_DIR, os.path.basename(f)))
    rc_file = os.path.join(GAME_DIR, "my_bot.rc")
    if not os.path.exists(rc_file):
        print("CASE 0000 RE score=0")
        print("TOTAL_SCORE 0"); print("CASES_OK 0"); print("CASES_TOTAL 1")
        return

    results = [("WA", 0)] * len(HOLDOUT_SEEDS)
    import concurrent.futures
    parallel = int(os.environ.get("DCSS_PARALLEL", str(len(HOLDOUT_SEEDS))))
    parallel = max(1, min(parallel, len(HOLDOUT_SEEDS)))
    with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as ex:
        futures = {ex.submit(run_game, seed, i + 1, rc_file): i
                   for i, seed in enumerate(HOLDOUT_SEEDS)}
        for fut in concurrent.futures.as_completed(futures):
            i = futures[fut]
            try: results[i] = fut.result()
            except Exception as e:
                results[i] = ("WA", 0)
    details = []
    for i, (status, score) in enumerate(results):
        # Intentionally NO seed in the CASE line.
        print(f"CASE {i:04d} {status} score={score}", flush=True)
        detail_status = "PASSED" if status == "OK" else "FAILED"
        details.append({
            "name": f"case_{i:04d}",
            "status": detail_status,
            "score": score,
            "message": (
                f"morgue_score={score}; raw_status={status}. "
                "Pass/fail only means the game produced an accepted morgue; "
                "quality is the numeric morgue score."
            ),
        })
    mean = round(sum(s for _, s in results) / max(len(results), 1), 1)
    ok = sum(1 for s, _ in results if s == "OK")
    total = len(HOLDOUT_SEEDS)
    print(f"TOTAL_SCORE {mean}")
    print(f"CASES_OK {ok}")
    print(f"CASES_TOTAL {total}")
    case_scores = {f"case_{i:04d}_score": score for i, (_, score) in enumerate(results)}
    structured = {
        "valid": ok == total,
        "score": mean,
        "pass_rate": ok / total if total else 0.0,
        "summary": (
            f"Score/TOTAL_SCORE={mean}; Passed={ok}/{total} is only the accepted-morgue "
            "validity count, not the quality metric. Per-case morgue scores are "
            "reported in metrics and in sebench-submit --details."
        ),
        "details": details,
        "metrics": {
            "total_score": mean,
            "cases_ok": ok,
            "cases_total": total,
            **case_scores,
        },
    }
    print(">>>>> Start Structured Result")
    print(json.dumps(structured, sort_keys=True))
    print(">>>>> End Structured Result")

if __name__ == "__main__":
    main()
