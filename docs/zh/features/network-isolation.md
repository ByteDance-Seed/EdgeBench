---
title: 网络隔离
---

# 网络隔离

隔离的 work 容器只能访问 judge server。Agent 仍然能用模型，因为模型请求经由 judge server 的 LLM 网关转发；除此之外它什么都不需要：任务用到的东西都在镜像里，Agent 也在启动时拷入。

每道题在 `task.toml` 的 `[environment]` 中设置 `internet`，大多数任务是隔离的。可以用 `--disable-internet` 或 `--enable-internet` 按次覆盖，或在[实验配置](/zh/configuration/experiments)中逐题设置 `internet:`。

Judge 容器默认完全没有网络，除非任务设置了 `[judge] internet = true`（只有 LLM 评分的任务这样设置），因为评分程序要运行提交的代码。游戏容器保留网络，以便 judge server 连接；它们不运行提交的代码。

| Backend | 实现方式 | 前提 |
|---------|----------|------|
| Docker | 宿主机上的 iptables 规则，运行结束时删除 | 对 `iptables` 有免密 `sudo` |
| Kubernetes | 每个 Pod 一个 NetworkPolicy，只放行 judge 和 DNS | CNI 实际执行 NetworkPolicy；先用小任务验证 |
| E2B | Sandbox 的网络规则（`update_network`） | — |

隔离的容器不会得到代理变量。如果宿主机访问模型 API 需要代理，设置 `SFORGE_HTTPS_PROXY`，LLM 网关会使用它。

## 给出题人

`internet = false` 时，Agent 需要的一切都必须在 work 镜像里：不要让它下载依赖或克隆仓库。SForge 会在 prompt 中加入网络限制说明。只有评分本身需要网络时才设置 `[judge] internet = true`，并在 `NOTES.md` 中说明原因。
