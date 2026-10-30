#!/bin/bash
# Judge entry point (task.toml judge.cmd). Runs with workdir = /home/workspace/cas_rust_benchmark
# after the filtered submission (agent-start/...) has been extracted there.
#
# This is v1's eval_cmd verbatim except that the pristine bundle is already unpacked at
# /judge/bundle/cas_rust_benchmark (v1 shipped cas_rust_benchmark.tar.gz in the cwd and ran
# `tar -xzf cas_rust_benchmark.tar.gz -C /tmp/cas_eval`), and that the structured result is
# written to /opt/sforge/result.json by result.py instead of being printed between markers.
cd /home/workspace/cas_rust_benchmark && rm -rf /tmp/cas_eval /tmp/cas_score.out /tmp/cas_submitted_agent_start && mkdir -p /tmp/cas_eval \
 && if [ -d agent-start ]; then cp -a agent-start /tmp/cas_submitted_agent_start; rm -rf /tmp/cas_submitted_agent_start/target /tmp/cas_submitted_agent_start/vendor-deps /tmp/cas_submitted_agent_start/.git; fi \
 && cp -a /judge/bundle/. /tmp/cas_eval/ \
 && mkdir -p /tmp/cas_eval/run && cp -a /tmp/cas_eval/cas_rust_benchmark/workspace/. /tmp/cas_eval/run/ && cp -a /tmp/cas_eval/cas_rust_benchmark/judge/. /tmp/cas_eval/run/ \
 && if [ -d /tmp/cas_submitted_agent_start ]; then cp -a /tmp/cas_submitted_agent_start/. /tmp/cas_eval/run/agent-start/; fi \
 && cd /tmp/cas_eval/run && cc -c agent-start/.ghostty-stub/ghostty_vt_stub.c -o agent-start/.ghostty-stub/ghostty_vt_stub.o && ar rcs agent-start/.ghostty-stub/libghostty_vt.a agent-start/.ghostty-stub/ghostty_vt_stub.o \
 && chmod +x score.sh verify_task.sh agent-start/score.sh && bash score.sh agent-start > /tmp/cas_score.out 2>&1; cat /tmp/cas_score.out; python3 /judge/result.py
