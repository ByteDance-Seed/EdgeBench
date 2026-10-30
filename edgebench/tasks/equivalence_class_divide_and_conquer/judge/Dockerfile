# Judge image for equivalence_class_divide_and_conquer.
# Build context = the task directory:
#   sforge build --task equivalence_class_divide_and_conquer
#
# v1 judge.setup_cmds -> this file:
#   1 apt-get install python3                       -> apt-get install below (versions pinned to v1)
#   2 curl <internal TOS>/p2_judge.tar.gz           -> scripts/statements/std.cpp committed under judge/p2_judge/;
#                                                      the 1.1 GB of test data (P2/T*_*/data) in blob judge/blobs/p2_tests.tar.gz
#   3 tar xzf ... -C / --strip-components=1         -> COPY judge/p2_judge/ /opt/p2_judge/ (byte- and mode-identical)
#                                                      + COPY environment/workspace/ <cwd> (the tarball's home/workspace/p2;
#                                                      the published image carries the English statements, see NOTES.md)
#   4 rm -f tarball                                 -> nothing to remove
#   v1 eval_cmd + parser score_sum                  -> judge/grade.py (task.toml [judge].cmd)

# Base = bases/cpp (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3=3.10.6-1~22.04.1 python3-minimal=3.10.6-1~22.04.1 \
      python3.10=3.10.12-1~22.04.15 python3.10-minimal=3.10.12-1~22.04.15 \
      libpython3-stdlib=3.10.6-1~22.04.1 \
      libpython3.10-minimal=3.10.12-1~22.04.15 libpython3.10-stdlib=3.10.12-1~22.04.15 \
 && rm -rf /var/lib/apt/lists/*

COPY judge/p2_judge/ /opt/p2_judge/
# Hidden tests (task.toml [[blobs]]); ADD unpacks the tarball into P2/T*_*/data.
ADD judge/blobs/p2_tests.tar.gz /opt/p2_judge/prob/P2/
COPY environment/workspace/ /home/workspace/p2/
COPY judge/grade.py /judge/grade.py
RUN chmod 755 /judge/grade.py
WORKDIR /home/workspace/p2
CMD ["/bin/bash"]
