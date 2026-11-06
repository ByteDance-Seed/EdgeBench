#!/usr/bin/env python3
"""SE-Bench evaluator for exchange-core throughput task (JDK 17 compat)."""
import os
import re
import subprocess

WORK_DIR = "/home/workspace/exchange-core"
TIMEOUT = 1800
TEST_CLASS = "PerfThroughput#testThroughputPeak"

# For delombok (mvn main process) — needs exports to javac internals
DELOMBOK_OPTS = (
    "--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED "
    "--add-exports=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED "
    "--add-exports=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED "
    "--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED "
    "--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED "
    "--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED "
    "--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED "
    "--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED "
    "--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED "
    "--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED "
    "--add-opens=java.base/java.lang=ALL-UNNAMED "
    "--add-opens=java.base/java.util=ALL-UNNAMED "
    "--add-opens=java.base/java.lang.reflect=ALL-UNNAMED "
    "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED "
    "--add-opens=java.base/java.io=ALL-UNNAMED"
)

# For test JVM (surefire forked) — chronicle-core / agrona hot opens
TEST_JVM_OPTS = (
    "--add-opens=java.base/java.lang=ALL-UNNAMED "
    "--add-opens=java.base/java.util=ALL-UNNAMED "
    "--add-opens=java.base/java.lang.reflect=ALL-UNNAMED "
    "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED "
    "--add-opens=java.base/java.io=ALL-UNNAMED "
    "--add-opens=java.base/java.nio=ALL-UNNAMED "
    "--add-opens=java.base/jdk.internal.ref=ALL-UNNAMED"
)


def main():
    os.chdir(WORK_DIR)
    cmd = [
        "mvn", "-B", "test",
        f"-Dtest={TEST_CLASS}",
        "-Dmaven.compiler.source=1.8",
        "-Dmaven.compiler.target=1.8",
        "-DfailIfNoTests=false",
        f"-Dsurefire.argLine={TEST_JVM_OPTS}",
        f"-DargLine={TEST_JVM_OPTS}",
    ]
    env = {**os.environ, "MAVEN_OPTS": DELOMBOK_OPTS}
    try:
        proc = subprocess.run(cmd, env=env, capture_output=True,
                              text=True, timeout=TIMEOUT, cwd=WORK_DIR)
        output = proc.stdout + "\n" + proc.stderr
        rc = proc.returncode
    except subprocess.TimeoutExpired:
        print("CASE 0000 TLE score=0", flush=True)
        print("TOTAL_SCORE 0", flush=True)
        print("CASES_OK 0", flush=True)
        print("CASES_TOTAL 1", flush=True)
        return

    avg_match = re.search(r"Average[:\s]+(\d+\.\d+)\s*MT/s", output)
    round_matches = re.findall(r"^\s*\d+\.\s+(\d+\.\d+)\s*MT/s", output,
                               flags=re.MULTILINE)

    if avg_match:
        avg = float(avg_match.group(1))
    elif round_matches:
        avg = sum(float(v) for v in round_matches) / len(round_matches)
    else:
        tail = "\n".join(output.splitlines()[-80:])
        print("DEBUG: no MT/s line found. Output tail:", flush=True)
        print(tail, flush=True)
        status = "WA" if rc == 0 else "RE"
        print(f"CASE 0000 {status} score=0", flush=True)
        print("TOTAL_SCORE 0", flush=True)
        print("CASES_OK 0", flush=True)
        print("CASES_TOTAL 1", flush=True)
        return

    score = int(round(avg * 1000))
    status = "OK" if rc == 0 and score > 0 else "WA"
    print(f"CASE 0000 {status} score={score}  # Average={avg:.3f} MT/s",
          flush=True)
    print(f"TOTAL_SCORE {score}", flush=True)
    print(f"CASES_OK {1 if status == 'OK' else 0}", flush=True)
    print("CASES_TOTAL 1", flush=True)


if __name__ == "__main__":
    main()
