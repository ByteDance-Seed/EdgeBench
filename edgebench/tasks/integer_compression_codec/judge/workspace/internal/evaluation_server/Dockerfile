# Dockerfile for the remote evaluation service.
# The service itself (FastAPI + uvicorn) runs in this image; it invokes
# a *second* docker image (intcompress-runner) in --read-only/--network=none
# mode for every submission.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential gcc-12 g++-12 make \
      python3 python3-pip \
      docker.io binutils file ca-certificates \
      curl \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 60 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 60 \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir fastapi==0.112.0 uvicorn[standard]==0.30.0 \
                                 python-multipart==0.0.9

WORKDIR /app
COPY server.py runner_encode.cpp runner_decode.cpp ./
COPY intcompress.h ./

ENV IC_DATA_DIR=/srv/intcompress/data \
    IC_WORK_ROOT=/var/lib/intcompress/work \
    IC_RESULT_DIR=/var/lib/intcompress/results \
    IC_BASELINE=/srv/intcompress/baseline.json \
    IC_RUNNER_IMAGE=intcompress-runner:latest

# The runner image is built separately from intcompress-runner.Dockerfile.

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8080"]
