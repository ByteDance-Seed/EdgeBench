# Work image for exchange_core_throughput (agent workspace).
# Build context = the task directory:
#   sforge build --task exchange_core_throughput
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                    -> implied by COPY
#   1 git clone github.com/foreverpiano/exchange-core             -> environment/exchange-core/ = `git archive 2f85487`
#   2 git checkout 2f85487                                           of that public repo, minus src/test (see 5)
#   3 sed lombok-maven-plugin 1.18.12.0 -> 1.18.20.0 in pom.xml   -> same sed below (pom.xml is committed as upstream)
#   4 mvn -B -DskipTests -q dependency:resolve dependency:resolve-plugins
#                                                                 -> stage `m2`: the resulting /root/.m2/repository is
#                                                                    rebuilt offline-ready from Maven Central, every file
#                                                                    sha256-pinned (environment/m2/central.tsv)
#   5 rm -rf src/test && mkdir -p src/test/java                   -> src/test not committed here; empty dir created below
#   6 rm -rf .git && git init && git config user.* && git add -A && git commit -m init
#                                                                 -> same, with v1's commit date pinned (same commit hash)
#   (template) chown -R agent:agent <cwd>; USER agent             -> dropped (root)

ARG BASE_IMAGE

# ---- stage m2: pinned Maven local repository (shared verbatim with judge/Dockerfile) ----
FROM ${BASE_IMAGE} AS m2
COPY environment/m2/ /build/m2/
RUN python3 -I /build/m2/fetch_m2.py /build/m2/central.tsv /out/repository /build/m2/resolver-state.json

# ---- final ----
FROM ${BASE_IMAGE}
COPY --from=m2 /out/repository /root/.m2/repository
COPY environment/exchange-core/ /home/workspace/exchange-core/
WORKDIR /home/workspace/exchange-core
RUN sed -i 's|<version>1.18.12.0</version>|<version>1.18.20.0</version>|g' pom.xml \
 && mkdir -p src/test/java \
 && git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE='1780755912 +0000' GIT_COMMITTER_DATE='1780755912 +0000' git commit -m 'init' -q \
 && test "$(git rev-parse HEAD)" = 7afd8f211a2182911c289feb1b6ca4c38eeb1d7e
