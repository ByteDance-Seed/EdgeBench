---
title: 环境变量
---

# 环境变量

## 概述

SForge 大部分配置可通过 `SFORGE_*` 环境变量注入；仅 CLI/YAML 支持的字段（例如 Judge CPU/内存限制）会在下文单独说明。优先级如下：

```
默认值  <  环境变量  <  实验 YAML 配置  <  CLI 参数
```

代理、镜像源、API 密钥、路径、后端、Registry 和 Hub 配置都可以在运行时覆盖。

## 构建阶段变量

以下变量在 `sforge build` 时作为 Docker build arg 传入，仅在镜像构建过程中生效，**不会**写入最终镜像。

| 变量 | 用途 |
|------|------|
| `SFORGE_HTTP_PROXY` | Docker 构建时的 HTTP 代理 |
| `SFORGE_HTTPS_PROXY` | Docker 构建时的 HTTPS 代理 |
| `SFORGE_NO_PROXY` | 不走代理的地址 |
| `SFORGE_PYPI_INDEX_URL` | PyPI 镜像源（构建时设置 `PIP_INDEX_URL`） |
| `SFORGE_MAVEN_MIRROR_URL` | Maven 仓库镜像（构建时设置 `MAVEN_MIRROR_URL`） |
| `SFORGE_GO_PROXY` | Go 模块代理（构建时设置 `GOPROXY`） |
| `SFORGE_APT_MIRROR_URL` | APT 源镜像（重写 base 镜像中的 `/etc/apt/sources.list`） |
| `SFORGE_GIT_USER` | Git 用户名（用于私有仓库） |
| `SFORGE_GIT_TOKEN` | Git 访问令牌（通过 BuildKit secret 注入，**不会**存储在镜像中） |
| `SFORGE_EXTRA_HOSTS` | 构建时 DNS 覆盖，格式：`"host1:ip1,host2:ip2"` |

### 构建参数的工作原理

代理变量（`HTTP_PROXY`、`HTTPS_PROXY`、`NO_PROXY`）是 Docker 预定义的 build arg，会自动对 `RUN` 命令生效，但不会持久化到最终镜像层。

包管理镜像变量（`PIP_INDEX_URL`、`GOPROXY`、`MAVEN_MIRROR_URL`）以 `ARG` 指令声明，在 `RUN` 命令中可用，同样不会持久化。

## 运行阶段变量

通过 `sforge run` 运行 Agent 时使用，作为容器环境变量注入。

| 变量 | 用途 |
|------|------|
| `SFORGE_AGENT_API_KEY` | 传递给所选 Agent 的 API 密钥，会映射为该 Agent 需要的环境变量（`ANTHROPIC_AUTH_TOKEN` 或 `CODEX_API_KEY`） |
| `SFORGE_AGENT_API_BASE_URL` | API Base URL 覆盖，会传递给所选 Agent 支持的 base-url 环境变量 |
| `SFORGE_AGENT_MODEL` | Agent 模型覆盖 |
| `SFORGE_AGENT_EFFORT` | Agent 推理强度（`low`、`medium`、`high` 或 `max`） |
| `SFORGE_AGENT_TIMEOUT` | Agent 超时时间（秒） |
| `SFORGE_AGENT_EXTRA_ENV` | Agent 容器额外环境变量，格式：`"KEY1=VAL1,KEY2=VAL2"` |
| `SFORGE_HTTP_PROXY` | 运行阶段注入 Agent 容器的 HTTP 代理。不推荐常规使用；不兼容 `--disable-internet`。 |
| `SFORGE_HTTPS_PROXY` | 运行阶段注入 Agent 容器的 HTTPS 代理。不推荐常规使用；不兼容 `--disable-internet`。 |
| `SFORGE_NO_PROXY` | 运行阶段不走代理的地址 |
| `SFORGE_NODEJS_MIRROR_URL` | Node.js 下载镜像源（Agent 运行时安装使用） |
| `SFORGE_NPM_REGISTRY_URL` | NPM 仓库镜像（容器内设置 `npm_config_registry`） |
| `SFORGE_CLAUDE_CACHE_OPT` | 抑制 Claude Code 归属头和动态系统提示词段落，以便在第三方代理上获得更好的缓存命中率。设置为 `1` 启用。 |

::: warning 运行时直接代理
把 `SFORGE_HTTP_PROXY` / `SFORGE_HTTPS_PROXY` 直接注入 Agent 容器，会让容器通过代理获得网络访问能力。这个方式只适合极少数运行时下载依赖的场景，**不推荐**用于 LLM API 访问。

它也不兼容网络隔离模式（`--disable-internet`）。如果需要在网络隔离下通过企业代理访问 LLM API，请在宿主机运行 `sforge proxy`，并把 `SFORGE_AGENT_API_BASE_URL` 指向 `http://host.docker.internal:<port>`。

对于 E2B，宿主机通用的 `HTTP_PROXY` / `HTTPS_PROXY` 不会自动传入 Work Sandbox。只有
显式设置 `SFORGE_` 代理变量且远端能够访问该代理时才应转发；隔离模式始终移除代理并由
E2B 原生域名白名单直接放行。
:::

## Judge 变量

| 变量 | 用途 |
|------|------|
| `SFORGE_JUDGE_EXTRA_ENV` | Judge 容器额外环境变量，格式：`"KEY1=VAL1,KEY2=VAL2"` |
| `SFORGE_ADMIN_SECRET` | 可信 Host 用于注册 Judge 会话和 auto-eval 的凭证；未设置时在 `SFORGE_LOG_DIR` 下生成权限为 `0600` 的 secret 文件，不得注入 Work 容器。 |

## 资源限制变量

| 变量 | 用途 |
|------|------|
| `SFORGE_WORK_CPU_LIMIT` | Work 容器的 CPU 核数（例如 `4`） |
| `SFORGE_WORK_MEM_LIMIT` | Work 容器的内存限制（例如 `8g`） |

Judge CPU/内存限制目前通过 CLI 参数（`--judge-cpu-limit`、`--judge-mem-limit`）或实验 YAML（`judge_cpu_limit`、`judge_mem_limit`）设置，不通过环境变量读取。

## 容器后端变量

| 变量 | 默认值 | 用途 |
|------|--------|------|
| `SFORGE_BACKEND` | `docker` | 容器后端：`docker`、`k8s` 或官方 `e2b` |
| `SFORGE_K8S_NAMESPACE` | `default` | Kubernetes 命名空间 |
| `SFORGE_K8S_IMAGE_REGISTRY` | --- | K8s 镜像拉取使用的容器镜像仓库 |
| `SFORGE_K8S_KUBECONFIG` | --- | kubeconfig 文件路径 |
| `SFORGE_K8S_NODE_SELECTOR` | --- | K8s Pod 的节点选择器，格式：`"key1=val1,key2=val2"` |
| `SFORGE_E2B_TEMPLATE_MAP` | --- | E2B image key 到 Template 的显式映射 |
| `SFORGE_E2B_TEMPLATE_NAMESPACE` | --- | 已发布 E2B Template 的 namespace（例如 `edgebench`） |
| `SFORGE_E2B_SANDBOX_TTL` | `3600` | E2B Sandbox TTL（秒） |

## 路径变量

| 变量 | 默认值 | 用途 |
|------|--------|------|
| `SFORGE_LOG_DIR` | `logs/` | 覆盖日志输出目录 |
| `SFORGE_TASKS_DIR` | `tasks/` | 覆盖任务定义目录 |
| `SFORGE_REGISTRY` | --- | Docker Registry URL，用于 `pull`/`push` 命令 |

## 代理回退链

代理类变量会按优先级依次检查多个环境变量名：

| 配置项 | 检查的环境变量（优先匹配） |
|--------|--------------------------|
| `http_proxy` | `SFORGE_HTTP_PROXY` > `HTTP_PROXY` > `http_proxy` |
| `https_proxy` | `SFORGE_HTTPS_PROXY` > `HTTPS_PROXY` > `https_proxy` |
| `no_proxy` | `SFORGE_NO_PROXY` > `NO_PROXY` > `no_proxy` |

如果 shell 中已设置了 `HTTP_PROXY`，SForge 会自动识别。使用 `SFORGE_` 前缀可以在不影响其他工具的情况下单独覆盖。

这些代理值也会在 `sforge run` 时注入 Work 容器；使用 `--disable-internet` 时请取消设置，或使用 `sforge proxy` 转发 LLM API 请求。

## 构建与运行的解耦

::: warning 重要
构建阶段和运行阶段的变量完全独立。构建阶段变量仅在 `docker build` 时使用，**不会**写入镜像。运行阶段需要独立配置。
:::

具体来说：

- `SFORGE_PYPI_INDEX_URL` 仅影响 `sforge build`（镜像构建时的包安装）
- `SFORGE_AGENT_API_KEY` 仅影响 `sforge run`（Agent 执行）
- 代理设置会被构建和运行阶段共同读取。运行时直接代理不推荐使用，且不兼容网络隔离；通过上游代理访问 LLM API 时请使用 `sforge proxy`。

## 示例：完整配置

```bash
# 构建阶段
export SFORGE_HTTP_PROXY="http://proxy.corp.example:8080"
export SFORGE_HTTPS_PROXY="http://proxy.corp.example:8080"
export SFORGE_PYPI_INDEX_URL="https://mirrors.example.com/pypi/simple/"
export SFORGE_APT_MIRROR_URL="http://mirrors.example.com"
export SFORGE_GO_PROXY="https://goproxy.example.com"

# 运行阶段
export SFORGE_AGENT_API_KEY="sk-ant-..."
export SFORGE_AGENT_API_BASE_URL="https://api.anthropic.com"
export SFORGE_AGENT_MODEL="claude-sonnet-4-20250514"
export SFORGE_AGENT_TIMEOUT="7200"
export SFORGE_NODEJS_MIRROR_URL="https://mirrors.example.com/nodejs-release/"

# 资源限制
export SFORGE_WORK_CPU_LIMIT="4"
export SFORGE_WORK_MEM_LIMIT="8g"

# 容器后端（Kubernetes）
export SFORGE_BACKEND="k8s"
export SFORGE_K8S_NAMESPACE="sforge-runs"
export SFORGE_K8S_IMAGE_REGISTRY="registry.example.com/sforge"
```
