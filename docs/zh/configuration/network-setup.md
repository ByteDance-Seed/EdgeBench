---
title: 网络配置
---

# 网络配置

## 默认：无需额外配置

SForge 假设宿主机可以访问公网。在不受限的网络环境下不需要代理或镜像源：

```bash
sforge pull --task ad_placement_optimization

export SFORGE_AGENT_API_KEY="sk-ant-xxxx"
sforge run --task ad_placement_optimization --agent claude-code
```

只有当你的环境无法直接访问某个必需的服务时，才需要下面的配置。

## 哪些环节需要网络

| 环节 | 发起方 | 访问 |
|------|--------|------|
| `sforge pull` | 宿主机 Docker daemon | Docker Hub（`registry-1.docker.io`） |
| `sforge build` | 宿主机和 `docker build` | Docker Hub 等基础镜像仓库；Dockerfile 中固定版本的公开 URL、包索引和 apt 快照；本仓库 Release 中的任务 blob |
| `sforge run`（首次使用时构建 Agent bundle） | 宿主机 | nodejs.org 和 npm registry |
| `sforge run`（模型调用） | 宿主机上的 judge server | 模型 API |
| work 容器 | — | 隔离任务只能访问 judge server；`internet = true` 时可访问公网 |
| judge 容器 | — | 没有网络，除非任务设置 `[judge] internet = true`（LLM 评分任务） |

Work 容器从不直接访问模型 API：judge server 的 LLM 网关替它转发，所以隔离的容器不需要代理。

## 代理

为 SForge 单独设置代理，不影响宿主机上的其他工具：

```bash
export SFORGE_HTTP_PROXY="http://proxy.example:8080"
export SFORGE_HTTPS_PROXY="http://proxy.example:8080"
export SFORGE_NO_PROXY="localhost,127.0.0.1,host.docker.internal"
```

`SFORGE_` 前缀的变量未设置时，SForge 会回退到 `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY`。代理用于 `docker build`（作为 Docker 预定义的代理 build arg，不写入镜像）、LLM 网关转发模型请求，以及联网的 work 容器内部。隔离的 work 容器不会得到代理变量。

`sforge pull` 和 Kubernetes 节点拉镜像由 Docker daemon 或容器运行时完成，它们有自己的代理配置（Docker 是 `/etc/systemd/system/docker.service.d/http-proxy.conf`）。

## 镜像源

任务 Dockerfile 只下载固定版本的公开 URL，并做 sha256 校验或使用带哈希的 lockfile，因此构建不接受逐任务的镜像源设置。只要提供完全相同的字节，镜像源仍可用来加速传输，例如 `/etc/docker/daemon.json` 中的 Docker registry mirror，或设置为 `SFORGE_HTTPS_PROXY` 的透明缓存代理。

Agent bundle 在首次使用时于宿主机上构建：

```bash
export SFORGE_NODEJS_MIRROR_URL="https://nodejs.example.com/download/release/"
export npm_config_registry="https://npm.example.com"
```

任务 blob 可以用 `SFORGE_BLOB_URL=file:///path/to/blobs` 从本地副本读取（文件名为其 sha256）。
