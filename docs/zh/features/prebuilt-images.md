---
title: 预构建镜像
---

# 预构建镜像

`sforge pull` 拉取 `<registry>/<本地镜像>`，registry 依次取 `--registry`、`SFORGE_REGISTRY` 和 benchmark 的 `benchmark.toml`。

EdgeBench 的镜像由 CI 从本仓库构建，发布到 Docker Hub 的 `docker.io/seededge` 下，每个镜像一个仓库。这些就是 v1 镜像所在的仓库，v1 和现在的镜像只是 tag 不同：

| 本地镜像 | 发布为 |
|----------|--------|
| `edgebench.base.cpp:67f57d824691` | `docker.io/seededge/edgebench.base.cpp:67f57d824691` |
| `edgebench.work.ad_placement_optimization:7b2f533ff7d4` | `docker.io/seededge/edgebench.work.ad_placement_optimization:7b2f533ff7d4` |
| `edgebench.judge.ad_placement_optimization:1c6838c6d7fd` | `docker.io/seededge/edgebench.judge.ad_placement_optimization:1c6838c6d7fd` |

哈希由构成镜像的文件计算（见[任务格式](/zh/tasks/task-format#镜像与-base)），所以 tag 一定与构建它的任务目录一致。`sforge pull` 拉哪些 tag 由你的代码决定。

## 拉取

```bash
sforge pull --task ad_placement_optimization
sforge pull --task ad_placement_optimization smt_solver
sforge pull --all
```

`pull` 拉取 work 和 judge 镜像，并打上本地 key 作为 tag，`sforge run` 只需要这些。本地已有的镜像会跳过。镜像是公开的，但 Docker Hub 对匿名拉取限流；`sforge pull --all` 之前先 `docker login`（任意免费账号即可）。

如果改过某道题，它的哈希就变了，没有可拉的镜像：用 `sforge build --task <id>` 构建。

## EdgeBench 的镜像如何发布

`Task Images` 工作流（`.github/workflows/images.yml`）在每次推送到 `main` 且改动了 `edgebench/` 或镜像相关代码时运行：

1. 列出 registry 中还没有对应 tag 的 base 和任务（`tools/ci_images.py plan`；设置 `SFORGE_BENCHMARK` 后对任何 benchmark 都适用）。
2. 先构建并推送这些 base，再为每个缺失的任务各起一个 job 构建推送。

没有变化的任务会跳过，所以只改了一道题的 pull request 只会重建那道题。在 pull request 上工作流只构建改动的镜像，用来检查它们仍能构建成功；只有 `main` 上才推送镜像，使用仓库 secret `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN`。

## 自己的 Registry

`sforge push` 可以把镜像推到任何你有写权限的 registry 前缀下，名称和 tag 相同。可用于从集群附近的 registry 给 Kubernetes 提供镜像，或分享改过的任务镜像：

```bash
docker login registry.example.com
sforge build --task ad_placement_optimization
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
```

`push` 也会推送 base 镜像。其他机器这样拉取：

```bash
sforge pull --task ad_placement_optimization --registry registry.example.com/sforge
```

或者设置一次 `SFORGE_REGISTRY=registry.example.com/sforge`。Kubernetes 后端则把 `SFORGE_K8S_IMAGE_REGISTRY` 设为同一个前缀。
