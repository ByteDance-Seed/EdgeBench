# Judge image for tree_block_partitioning.
# Build context = the task directory:
#   sforge build --task tree_block_partitioning
#
# v1 judge.setup_cmds -> this file:
#   1 apt-get install --no-install-recommends python3            -> RUN apt-get below (pinned, same as the work image)
#   2 curl <internal TOS>/p1_judge.tar.gz                        -> files committed under judge/p1_judge/, except the
#                                                                    hidden data (P1/T*_*/data, 415 MB) in blob
#                                                                    judge/blobs/p1_data.tar.gz
#   3 tar xzf ... -C / --strip-components=1                      -> the tarball held /opt/p1_judge (grader, testlib.h,
#                                                                    statements, hidden data) and /home/workspace/p1
#                                                                    (= the work tarball): COPY both below
#   4 rm -f /tmp/p1_judge.tar.gz                                 -> nothing to remove
#   v1 eval_cmd + parser score_sum                               -> judge/run.sh + judge/grade.py ([judge].cmd)

# Base = bases/cpp (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      python3=3.10.6-1~22.04.1 \
      python3-minimal=3.10.6-1~22.04.1 \
      libpython3-stdlib=3.10.6-1~22.04.1 \
      python3.10=3.10.12-1~22.04.15 \
      python3.10-minimal=3.10.12-1~22.04.15 \
      libpython3.10-minimal=3.10.12-1~22.04.15 \
      libpython3.10-stdlib=3.10.12-1~22.04.15 \
      libmpdec3=2.5.1-2build2 \
      libreadline8=8.1.2-1 \
      readline-common=8.1.2-1 \
      libsqlite3-0=3.37.2-2ubuntu0.5 \
      media-types=7.0.0; \
    rm -rf /var/lib/apt/lists/*

# Grader + hidden data at the v1 path (eval_cmd and eval_common.py use it). All 0755 as in v1.
COPY judge/p1_judge/ /opt/p1_judge/
# Hidden data (task.toml [[blobs]]); ADD unpacks the tarball into P1/T*_*/data.
ADD judge/blobs/p1_data.tar.gz /opt/p1_judge/prob/P1/
# The v1 judge tarball also carried the workspace skeleton (empty T*.cpp stubs, statements,
# down/ samples); eval.py falls back to these stubs for any T*.cpp missing from the submission.
COPY environment/workspace/ /home/workspace/p1/
COPY judge/run.sh judge/grade.py /judge/
RUN set -eux; \
    find /opt/p1_judge -exec chmod 755 {} +; \
    cd /home/workspace/p1; \
    find . -type d -exec chmod 755 {} +; \
    chmod 644 T1.cpp T2.cpp T3.cpp T4.cpp T5.cpp T6.cpp prompt.txt */problem.md; \
    chmod 755 */down/*; \
    chmod 755 /judge/run.sh /judge/grade.py
WORKDIR /home/workspace/p1
CMD ["/bin/bash"]
