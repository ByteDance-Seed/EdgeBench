# EdgeBench base "rust" = v1 BENCHMARK.yaml `rust`: rust:1.78 + git curl jq build-essential.
# Reconstructs v1's sebench.base.rust:cab016678a20 (built 2026-06-02) minus the `agent` user and sudo
# (SCHEMA rule 3: root only).
# Built by `sforge build` as base-rust:<tree hash>
FROM rust:1.78@sha256:5907e96b0293eb53bcc8f09b4883d71449808af289862950ede9a0e3cca44ff5

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# apt is pinned to the Debian snapshot of v1's base build date; the stock sources file is
# restored afterwards so /etc/apt matches the upstream image.
ARG DEBIAN_SNAPSHOT=20260602T120000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/debian.sources /tmp/debian.sources.orig; \
    sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
           -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
           /etc/apt/sources.list.d/debian.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends git curl jq build-essential; \
    mv /tmp/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*; \
    git config --global safe.directory '*'

CMD ["bash"]
