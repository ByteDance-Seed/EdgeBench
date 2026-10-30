# Judge image for rust_multicrate_reconstruction (v1: edgebench.judge.rust_multicrate_reconstruction:b749374fe7bc).
# Build context = the task directory:
#   sforge build --task rust_multicrate_reconstruction
#
# v1's judge image = base + the same toolchain step as the work image + the whole
# cas_rust_benchmark.tar.gz bundle (160 MB) in the cwd, unpacked by eval_cmd at judge time.
# Here the bundle is rebuilt unpacked at /judge/bundle/cas_rust_benchmark/{workspace,judge}
# from the same committed sources as the work image (environment/workspace, environment/vendor)
# plus judge/cas_judge (the bundle's judge/ dir: scorer, hidden tests, manifest).
ARG BASE_IMAGE

FROM ${BASE_IMAGE} AS vendor
COPY environment/vendor/build_vendor.py environment/vendor/vendor-manifest.tsv /tmp/vendor/
RUN python3 -I /tmp/vendor/build_vendor.py --manifest /tmp/vendor/vendor-manifest.tsv --out /vendor-deps
COPY environment/vendor/claude_rs/ /vendor-deps/claude_rs/

FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive

COPY environment/setup_toolchain.sh environment/rust-1.88.0-toolchain.sha256 /tmp/toolchain/
RUN sh /tmp/toolchain/setup_toolchain.sh && rm -rf /tmp/toolchain

COPY environment/workspace/ /judge/bundle/cas_rust_benchmark/workspace/
COPY --from=vendor /vendor-deps/ /judge/bundle/cas_rust_benchmark/workspace/agent-start/vendor-deps/
COPY judge/cas_judge/ /judge/bundle/cas_rust_benchmark/judge/
COPY judge/run.sh judge/result.py /judge/

# The submission is extracted here by the harness (task.toml environment.cwd).
RUN mkdir -p /home/workspace/cas_rust_benchmark
WORKDIR /home/workspace/cas_rust_benchmark
CMD ["bash"]
