# Judge image for bipedalwalker_locomotion_rl.
# Build context = the task directory:
#   sforge build --task bipedalwalker_locomotion_rl
#
# v1 judge.setup_cmds -> this file:
#   0 echo ...-20260530 (no-op)                                 -> dropped
#   1 mkdir -p /tmp/loco-src <cwd>                              -> implied
#   2-4 clone + unzip + cp -a sebench-loco-rl/. <cwd>           -> COPY environment/workspace/ + judge/sebench_eval.py + judge/eval/
#                                                                  (together = the whole zip, byte-identical)
#   5-8 pip install (same four lines as work)                   -> same environment/pipinstall.sh (shared layer)
#   9 chmod +x sebench_eval.py submission/train.py              -> chmod 755 below
#  10 chmod -R 500 <cwd>/eval                                   -> chmod 500 below
#  11 rm -rf /tmp/...                                           -> nothing to remove
#   v1 eval_cmd + parser structured_json                        -> judge/run.sh + judge/emit_result.py (task.toml [judge].cmd)
#   v1 judge has no workspace git repo; none is made here.

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN --mount=type=bind,source=environment,target=/mnt/lock sh /mnt/lock/pipinstall.sh

COPY environment/workspace/ /home/workspace/loco-rl/
COPY judge/sebench_eval.py /home/workspace/loco-rl/sebench_eval.py
COPY judge/eval/ /home/workspace/loco-rl/eval/
RUN cd /home/workspace/loco-rl \
 && chmod 755 sebench_eval.py submission/train.py \
 && chmod -R 500 eval
COPY judge/run.sh judge/emit_result.py /judge/
RUN chmod 755 /judge/run.sh && chmod 644 /judge/emit_result.py
WORKDIR /home/workspace/loco-rl
CMD ["python3"]
