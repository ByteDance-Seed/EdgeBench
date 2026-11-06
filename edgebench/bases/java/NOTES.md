# base: java

Reproduces v1 `edgebench.base.java` (BENCHMARK.yaml `java`: `maven:3.9-eclipse-temurin-17`
+ git curl jq build-essential ant unzip python3) minus `sudo` and the `agent` user.

## FROM provenance
`maven:3.9-eclipse-temurin-17@sha256:9f43af45b81b1505b907768c55da4e3df34064267c89354d0707c827e79de949`
(linux/amd64 manifest; Maven 3.9.16, Temurin jdk-17.0.19+10, Ubuntu 24.04.4, built
2026-06-02). All 10 rootfs diff_ids equal the first 10 layers of the published v1 image.
Found through the docker-library/repo-info history of the tag (2026-06-02); pinned by the
platform manifest because the multi-arch index digest changed while the amd64 image did not.

## Packages
Ubuntu archive snapshot `20260617T120000Z` (v1 base built 2026-06-17 12:13 UTC), explicit
versions: git 1:2.43.0-1ubuntu7.3, curl 8.5.0-2ubuntu10.9, jq 1.7.1-3ubuntu0.24.04.2,
build-essential 12.10ubuntu1, ant 1.10.14-1, unzip 6.0-28ubuntu4.1, python3 3.12.3-0ubuntu2.1.
As in v1, `ant` pulls in default-jre-headless = openjdk-21-jre-headless, so `/usr/bin/java`
(alternatives) is Java 21, while `java`/`mvn` on PATH are Temurin 17 (`/opt/java/openjdk/bin`
first). Stock `ubuntu.sources` is restored after the install.

## Diff vs published v1 (verified: dpkg list, full file tree with sha256/mode/owner, env,
## ENTRYPOINT/CMD, WORKDIR)
* Missing on purpose: `sudo` and its dependency `libapparmor1`; the `agent` user/group.
* `/tmp/hsperfdata_root` (an empty dir shipped by the upstream image and kept in v1) is
  removed: Verified images leave nothing under /tmp. A JVM recreates it at run time.
* `/etc/ssl/certs/java/cacerts` differs in bytes (the keystore is generated at install time)
  but holds the same 144 certificates (identical fingerprint list).
* Derived files: `/etc/ld.so.cache`, dpkg status, apt extended_states.
* Everything else is identical. Env (JAVA_HOME, MAVEN_HOME, MAVEN_CONFIG=/root/.m2, LANG/LC_ALL,
  TZ), `ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]`, `CMD ["mvn"]`, user root: identical.
  java 17.0.19, Maven 3.9.16, Ant 1.10.14, Python 3.12.3, gcc 13.3.0, git 2.43.0.
