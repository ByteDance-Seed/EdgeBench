# Agent local development environment.
# Mirrors the remote evaluation environment except without sandboxing.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential gcc-12 g++-12 clang-15 make \
      python3 python3-pip python3-numpy \
      curl ca-certificates file strace linux-tools-common \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 60 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 60 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . /workspace

# Pre-build the baseline so the container is immediately runnable.
RUN make clean && make -j"$(nproc)"

CMD ["/bin/bash"]
