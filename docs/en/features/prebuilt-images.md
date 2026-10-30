---
title: Pre-built Images
---

# Pre-built Images

`sforge pull` fetches `<registry>/<local image>`, where the registry comes from `--registry`, `SFORGE_REGISTRY` or the benchmark's `benchmark.toml`.

EdgeBench's images are built in CI from this repository and published to Docker Hub under `docker.io/seededge`, one repository per image. These are the same repositories as the v1 images; v1 and current images differ only in their tags:

| Local image | Published as |
|-------------|--------------|
| `edgebench.base.cpp:67f57d824691` | `docker.io/seededge/edgebench.base.cpp:67f57d824691` |
| `edgebench.work.ad_placement_optimization:7b2f533ff7d4` | `docker.io/seededge/edgebench.work.ad_placement_optimization:7b2f533ff7d4` |
| `edgebench.judge.ad_placement_optimization:1c6838c6d7fd` | `docker.io/seededge/edgebench.judge.ad_placement_optimization:1c6838c6d7fd` |

The hash is computed from the files that go into the image (see [Task Format](/en/tasks/task-format#images-and-bases)), so a tag always matches the task directory it was built from. Your checkout decides which tags `sforge pull` asks for.

## Pull

```bash
sforge pull --task ad_placement_optimization
sforge pull --task ad_placement_optimization smt_solver
sforge pull --all
```

`pull` fetches the work and judge images and tags them with their local keys, which is all `sforge run` needs. Images already present locally are skipped. The images are public, but Docker Hub rate-limits anonymous pulls; run `docker login` (any free account) before `sforge pull --all`.

If you changed a task, its hashes change and there is nothing to pull: build it with `sforge build --task <id>`.

## How EdgeBench's Images Are Published

The `Task Images` workflow (`.github/workflows/images.yml`) runs on every push to `main` that touches `edgebench/` or the image code:

1. It lists the bases and tasks whose image tags are not yet in the registry (`tools/ci_images.py plan`, which works for any benchmark set with `SFORGE_BENCHMARK`).
2. It builds and pushes those bases first, then each missing task, one job per task.

Unchanged tasks are skipped, so a pull request that edits one task rebuilds only that task. On pull requests the workflow only builds the changed images, as a check that they still build; images are pushed only from `main`, with the `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` repository secrets.

## Your Own Registry

`sforge push` publishes images under any registry prefix you can write to, with the same names and tags. This is how you serve images to a Kubernetes cluster from a registry near it, or share images of tasks you have changed:

```bash
docker login registry.example.com
sforge build --task ad_placement_optimization
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
```

`push` also pushes the base image. Other machines then pull with:

```bash
sforge pull --task ad_placement_optimization --registry registry.example.com/sforge
```

or set `SFORGE_REGISTRY=registry.example.com/sforge` once. For the Kubernetes backend set `SFORGE_K8S_IMAGE_REGISTRY` to the same repository.
