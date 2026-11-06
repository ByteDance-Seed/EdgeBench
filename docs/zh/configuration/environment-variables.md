---
title: 环境变量
---

# 环境变量

## 概述

SForge 只读取少量 `SFORGE_*` 环境变量。凡是有 CLI 参数的设置（模型、推理强度、超时、backend、资源限制）都用参数或[实验配置](/zh/configuration/experiments)设置，不用环境变量。优先级为：

```
默认值  <  环境变量  <  实验 YAML  <  CLI 参数
```

实验文件的 `env:` 段会在读取其他内容之前设置到 `sforge run` 进程中。

## Agent

| 变量 | 用途 |
|------|------|
| `SFORGE_AGENT_API_KEY` | 模型 API key。它只留在宿主机上：由 judge server 的 LLM 网关加到 Agent 的请求里 |
| `SFORGE_AGENT_API_BASE_URL` | 模型 API 端点，不用 Agent 默认 API 时设置（Claude Code 和 OpenCode 默认 Anthropic，Codex 默认 OpenAI） |
| `SFORGE_AGENT_EXTRA_ENV` | 传给 work 容器的额外变量，格式 `"KEY1=VAL1,KEY2=VAL2"`（例如 Claude Code 的模型路由变量） |
| `SFORGE_NODEJS_MIRROR_URL` | 宿主机构建 Agent bundle 时使用的 Node.js 下载镜像（压缩包仍按固定 sha256 校验） |
| `SFORGE_CACHE_DIR` | Agent bundle 和 `sforge replay` 的缓存目录（默认 `~/.cache/sforge`） |

## Judge

| 变量 | 用途 |
|------|------|
| `SFORGE_JUDGE_EXTRA_ENV` | 传给 judge 容器的变量，格式 `"KEY1=VAL1,KEY2=VAL2"`，例如 LLM 评分任务需要的凭据。Judge 容器不会从宿主机得到任何其他东西 |
| `SFORGE_ADMIN_SECRET` | `sforge run` 与外部 `sforge serve` 之间的共享密钥（会话登记、auto-eval、用量查询）。未设置时，`sforge serve` 在 `SFORGE_LOG_DIR` 下创建权限为 `0600` 的文件，`sforge run` 从同一位置读取；进程内 judge 使用随机值。绝不能暴露给 work 容器 |

## 镜像与任务

| 变量 | 默认值 | 用途 |
|------|--------|------|
| `SFORGE_BENCHMARK` | `edgebench` | benchmark 目录，即 `-b` 的默认值 |
| `SFORGE_LOG_DIR` | `logs/` | 构建日志和运行输出 |
| `SFORGE_REGISTRY` | benchmark 的 `registry` | `sforge pull` / `sforge push` 使用的 registry 前缀，镜像地址为 `<前缀>/<镜像>:<tag>` |
| `SFORGE_BLOB_URL` | benchmark 的 `blob_url` | `sforge build` 下载任务 blob 的地址，形如 `<url>/<sha256>`（可用 `file://` 指向本地副本） |

## 代理

| 配置 | 依次检查的环境变量（先命中者生效） |
|------|-----------------------------------|
| HTTP 代理 | `SFORGE_HTTP_PROXY` > `HTTP_PROXY` > `http_proxy` |
| HTTPS 代理 | `SFORGE_HTTPS_PROXY` > `HTTPS_PROXY` > `https_proxy` |
| 不走代理的地址 | `SFORGE_NO_PROXY` > `NO_PROXY` > `no_proxy` |

代理在哪些环节使用，见[网络配置](/zh/configuration/network-setup#代理)。

## 容器后端

| 变量 | 默认值 | 用途 |
|------|--------|------|
| `SFORGE_K8S_NAMESPACE` | `default` | Kubernetes namespace |
| `SFORGE_K8S_IMAGE_REGISTRY` | `SFORGE_REGISTRY`，否则 benchmark 的 `registry` | Pod 拉取镜像的 registry 前缀 |
| `SFORGE_K8S_KUBECONFIG` | --- | kubeconfig 文件路径 |
| `SFORGE_K8S_NODE_SELECTOR` | --- | Pod 的节点选择器，格式 `"key1=val1,key2=val2"` |
| `SFORGE_E2B_TEMPLATE_NAMESPACE` | --- | 共享 E2B Template 所在的 namespace（不设置则使用你自己团队的 Template） |
| `SFORGE_E2B_TEMPLATE_MAP` | --- | 显式的镜像 key 到 Template 的映射，覆盖推导出的名称。内联 `"image_key=template,..."`，或以 `.json` 结尾、内容为 JSON 对象的文件路径 |
| `SFORGE_E2B_PROVIDER` | `e2b` | E2B 兼容的 provider：`e2b`（官方）或 `vefaas`（火山引擎 veFaaS）。`run` 和 `serve` 两端都要设置 |

E2B SDK 自己读取 `E2B_API_KEY`（其他端点还需 `E2B_DOMAIN`）。

## 示例

```bash
# 模型
export SFORGE_AGENT_API_KEY="sk-ant-..."

# LLM 评分任务的凭据
export SFORGE_JUDGE_EXTRA_ENV="SFORGE_JUDGE_API_KEY=sk-...,SFORGE_JUDGE_MODEL=gpt-5.5"

# Kubernetes
export SFORGE_K8S_NAMESPACE="sforge-runs"

sforge run --backend k8s --task ad_placement_optimization --agent claude-code \
  --model claude-opus-4-8 --timeout 43200 \
  --work-cpu-limit 4 --work-mem-limit 16g \
  --judge-advertise 10.0.0.12 --judge-port 8080
```
