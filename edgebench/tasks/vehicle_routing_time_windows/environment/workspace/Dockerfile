# Local development environment that matches the remote evaluation runner.
# Build:  docker build -t cvrptw-dev .
# Use  :  docker run --rm -it -v $PWD:/work -w /work cvrptw-dev bash

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        g++-12 \
        clang-15 \
        make \
        python3 python3-pip python3-numpy \
        time \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 60 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 60

# Lock CPU governor docs (informational, no effect inside container).
ENV CXXSTD="-std=c++17" OPT="-O3 -march=x86-64-v3 -DNDEBUG"

WORKDIR /work

CMD ["bash"]
