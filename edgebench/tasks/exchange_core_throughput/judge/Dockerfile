# Judge image for exchange_core_throughput.
# Build context = the task directory:
#   sforge build --task exchange_core_throughput
#
# v1 judge.setup_cmds -> this file:
#   0-2 mkdir, git clone + checkout 2f85487                        -> environment/exchange-core/ + judge/upstream-src-test/
#                                                                    (= `git archive 2f85487`, src/test kept apart)
#   3 sed lombok-maven-plugin 1.18.12.0 -> 1.18.20.0              -> same sed below
#   4 rm -f src/test/.../perf/modules/ITOrderBook*.java           -> same rm below
#   5 sed: drop .matchingEnginesNum/.riskEnginesNum/.msgsInGroupLimit from PerfThroughput.java -> same sed below
#   6 mvn -B -DskipTests -q dependency:resolve dependency:resolve-plugins
#                                                                 -> stage `m2` (identical to environment/Dockerfile)
#      + the artifacts v1's judge downloaded from Maven Central at *run time* (surefire's JUnit Platform
#        provider and its deps; v1's judge container had internet) -> judge/m2-extra/central.tsv
#   7 rm -rf .git && git init && ... commit -m init                -> same, v1's commit date pinned (same commit hash)
#   8 heredoc > /tmp/eval_exchange_core.py                         -> /judge/eval_exchange_core.py (byte-identical)
#   eval_cmd `cd <cwd> && python3 /tmp/eval_exchange_core.py` + parser score_sum -> judge/run.sh + write_result.py

ARG BASE_IMAGE

# ---- stage m2: pinned Maven local repository ----
FROM ${BASE_IMAGE} AS m2
COPY environment/m2/ /build/m2/
RUN python3 -I /build/m2/fetch_m2.py /build/m2/central.tsv /out/repository /build/m2/resolver-state.json
COPY judge/m2-extra/ /build/m2-extra/
RUN python3 -I /build/m2/fetch_m2.py /build/m2-extra/central.tsv /out/repository /build/m2-extra/resolver-state.json

# ---- final ----
FROM ${BASE_IMAGE}
COPY --from=m2 /out/repository /root/.m2/repository
COPY environment/exchange-core/ /home/workspace/exchange-core/
COPY judge/upstream-src-test/ /home/workspace/exchange-core/src/test/
WORKDIR /home/workspace/exchange-core
RUN sed -i 's|<version>1.18.12.0</version>|<version>1.18.20.0</version>|g' pom.xml \
 && rm -f src/test/java/exchange/core2/tests/perf/modules/ITOrderBook*.java \
 && sed -i '/\.matchingEnginesNum([0-9]*)/d; /\.riskEnginesNum([0-9]*)/d; /\.msgsInGroupLimit([0-9]*)/d' src/test/java/exchange/core2/tests/perf/PerfThroughput.java \
 && git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE='1780756251 +0000' GIT_COMMITTER_DATE='1780756251 +0000' git commit -m 'init' -q \
 && test "$(git rev-parse HEAD)" = 738fe560a020bb77d0336da0d97c7ccfe905155a
COPY judge/eval_exchange_core.py judge/run.sh judge/write_result.py /judge/
RUN chmod 755 /judge/eval_exchange_core.py /judge/run.sh /judge/write_result.py
