# Judge image for integer_compression_codec.
# Build context = the task directory:
#   sforge build --task integer_compression_codec
#
# v1 judge.setup_cmds -> this file:
#   0 rm -rf /tmp/sebench-src <cwd> && mkdir -p ...          -> implied by COPY
#   1 git clone se-bmk-intern (branch <author>)           -> sources committed in the task dir
#   2 cp -R .../integer-compression-codec-judge/. <cwd>/       -> COPY environment/workspace/ + judge/workspace/
#                                                                (the published judge bundle = the agent files, with the same
#                                                                English docs, plus evaluation_server/, internal/, runner_judge.py)
#   3 apt-get install python3 python3-numpy                    -> environment/install_python.sh (versions pinned)
#   4 mkdir -p outputs data .judge-bin                         -> same
#   5 python3 tools/gen_data.py --full --out-dir data          -> same command (1.8 GB, generated), checked against v1 sha256
#   6 chmod +x runner_judge.py tools/submit.sh                 -> same
#   v1 eval_cmd + parser structured_json                       -> judge/run.sh + judge/emit_result.py (task.toml [judge].cmd)

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/install_python.sh /tmp/install_python.sh
RUN sh /tmp/install_python.sh && rm /tmp/install_python.sh

COPY environment/workspace/ /home/workspace/integer-compression-codec/
COPY judge/workspace/ /home/workspace/integer-compression-codec/
COPY judge/data.sha256 judge/run.sh judge/emit_result.py /judge/
WORKDIR /home/workspace/integer-compression-codec
# Hidden full-scale datasets (8 files, 1.8 GB). Same generator and seeds as the public
# sample, only N differs; regenerated at build time and checked against the v1 bytes.
RUN mkdir -p outputs data .judge-bin \
 && python3 tools/gen_data.py --full --out-dir data \
 && sha256sum -c /judge/data.sha256 \
 && chmod +x runner_judge.py tools/submit.sh \
 && chmod 755 /judge/run.sh /judge/emit_result.py
CMD ["/bin/bash"]
