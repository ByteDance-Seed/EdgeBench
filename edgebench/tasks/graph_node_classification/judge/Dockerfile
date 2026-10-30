# Judge image for graph_node_classification.
# Build context = the task directory:
#   sforge build --task graph_node_classification
#
# v1 judge.setup_cmds -> this file:
#   0-1 mkdir + git clone original task repo                     -> files committed under environment/workspace/ + judge/workspace/
#   2 pip install torch==2.2.2+cpu                               -> same environment/pipinstall.sh (shared layer with work)
#   3-6 cp README.md, problem.md, solution_template.py x2        -> COPY environment/workspace/ (same files as work)
#   7-10 cp runner.py verifier.py config.yaml judge_eval.py      -> COPY judge/workspace/
#   11-13 cp data.zip, unzip into <cwd>, rm data.zip             -> blob judge/blobs/squirrel_data.tar.gz (= the zip's
#                                                                   data/ tree, byte-identical), ADD unpacks it
#   14 rm -rf /tmp/sebench_resources                             -> nothing to remove
#   v1 eval_cmd + parser structured_json                         -> judge/run.sh + judge/emit_result.py (task.toml [judge].cmd)
#   v1 judge has no workspace git repo; none is made here.

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN --mount=type=bind,source=environment,target=/mnt/lock sh /mnt/lock/pipinstall.sh

COPY environment/workspace/ /home/workspace/045_graph_node_classification/
COPY judge/workspace/ /home/workspace/045_graph_node_classification/
# data/ (46 files, 626 MB unpacked: Squirrel graph, node features, 10 official Geom-GCN splits incl. test labels)
ADD judge/blobs/squirrel_data.tar.gz /home/workspace/045_graph_node_classification/
RUN cd /home/workspace/045_graph_node_classification/data/squirrel && sha256sum -c --quiet checksums.sha256
COPY judge/run.sh judge/emit_result.py /judge/
RUN chmod 755 /judge/run.sh && chmod 644 /judge/emit_result.py
WORKDIR /home/workspace/045_graph_node_classification
CMD ["python3"]
