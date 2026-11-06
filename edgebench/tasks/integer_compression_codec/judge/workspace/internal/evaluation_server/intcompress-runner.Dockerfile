# Runner image — used to compile submissions AND to execute the runner_encode/
# runner_decode binaries. Pre-builds the two standalone runners so that the
# service only needs to bind-mount the submission's libintcompress.so.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential gcc-12 g++-12 make binutils \
      libc-bin \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 60 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 60 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/runners
COPY intcompress.h runner_encode.cpp runner_decode.cpp /opt/runners/

# NB: -rdynamic so dlopen can locate symbols; link against libdl & libpthread
RUN g++ -std=c++17 -O3 -march=x86-64-v3 -I/opt/runners \
        -o /usr/local/bin/runner_encode /opt/runners/runner_encode.cpp -ldl && \
    g++ -std=c++17 -O3 -march=x86-64-v3 -I/opt/runners \
        -o /usr/local/bin/runner_decode /opt/runners/runner_decode.cpp -ldl

# The server bind-mounts /workspace read-only from the submission dir.
WORKDIR /workspace
