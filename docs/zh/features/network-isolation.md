---
title: 网络隔离
---

# 网络隔离

网络隔离用于阻止 Agent 直接访问互联网，只允许 Work 容器/Pod 访问必要的 Judge Server 和 AI API 端点。

## 使用方法

```bash
# 通过 CLI 参数禁用互联网
sforge run --task <task> --agent claude-code --disable-internet

# 通过任务 JSON 配置默认禁用互联网
{ "internet": false }

# 强制启用网络，覆盖任务 JSON
sforge run --task <task> --agent claude-code --enable-internet
```

`--disable-internet` 的具体实现取决于容器后端：

| Backend | 实现方式 |
|---------|----------|
| Docker | 宿主机 iptables/ip6tables 规则 |
| Kubernetes | Kubernetes NetworkPolicy |
| E2B | E2B `update_network` allow/deny 规则 |

## 允许访问的端点

网络隔离启用后，SForge 会为 Work 容器/Pod 构造出站白名单：

- Judge Server URL（`--judge-url`）
- Agent API Base URL（`SFORGE_AGENT_API_BASE_URL` 或 Agent 默认 API URL）
- DNS（Kubernetes backend 中允许 TCP/UDP 53）

除这些端点外，其他出站流量会被阻断。依赖下载、访问 GitHub、访问外部包仓库等操作应在镜像构建阶段完成。

## Docker backend

Docker backend 使用宿主机侧 iptables/ip6tables 进行隔离。

### 工作原理

- 为每个 Work 容器创建独立的 iptables 链（`SFORGE_<container_id>`）
- 白名单放行 TCP 到 Judge Server IP:端口和 AI API IP:端口
- 允许 established/related 连接
- 丢弃其他出站流量
- 完全阻断 IPv6
- 创建容器时 drop `NET_RAW` capability
- 容器停止时自动清理规则

### 前提条件

- 需要在宿主机上运行 Docker backend
- `sudo -n iptables` 必须可用，即 iptables 免密 sudo
- 不能直接与 `SFORGE_HTTP_PROXY` / `SFORGE_HTTPS_PROXY` 同时使用

如果权限不足，运行会失败并提示配置 passwordless sudo for iptables。

## Kubernetes backend

Kubernetes backend 使用 `NetworkPolicy` 对 Work Pod 的 egress 进行限制。

### 工作原理

SForge 会为每个 Work Pod 创建一个 NetworkPolicy：

- NetworkPolicy 名称形如 `sforge-iso-<pod-name>`
- 通过标签 `sforge-pod=<pod-name>` 只选择当前 Work Pod
- `policyTypes` 包含 `Egress`
- egress 白名单包含：
  - Judge Server IP:端口
  - AI API IP:端口
  - DNS TCP/UDP 53
- Pod 清理时同时删除对应 NetworkPolicy

### 前提条件

- 集群 CNI 必须支持并执行 Kubernetes NetworkPolicy
- 当前 kubeconfig 需要有创建、查询、删除 NetworkPolicy 的权限
- `--judge-url` 必须是 Pod 可访问的地址，例如宿主机内网 IP、LoadBalancer、Ingress 或集群内 Service
- 如果 API URL 是域名，SForge 会在启动时解析为 IPv4，并把解析到的 IP 写入 NetworkPolicy

示例：

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --judge-url http://10.0.0.12:8080 \
  --disable-internet
```

::: warning
NetworkPolicy 是否真正生效取决于集群 CNI。部分集群即使成功创建 NetworkPolicy，也可能不会实际拦截流量。首次使用时建议用小任务验证隔离效果。
:::

## E2B backend

E2B backend 通过官方 `update_network` API 下发白名单。E2B 规则按 Host
生效，不支持端口粒度；允许某个域名意味着允许访问该域名的所有端口。E2B API
当前接受 IPv4 全流量选择器（`0.0.0.0/0`），但会拒绝 `::/0`，因此 SForge 使用平台
支持的选择器，不发送无效的 IPv6 规则。deny 规则会一直保留到 Sandbox 被删除，宿主机
通用代理变量也不会自动传入 E2B Sandbox。

## 配合代理使用：`sforge proxy`

直接把 `SFORGE_HTTP_PROXY` / `SFORGE_HTTPS_PROXY` 注入 Work 容器与网络隔离不兼容。如果 AI API 必须通过企业代理访问，推荐在宿主机上启动 `sforge proxy`，然后只允许 Work 容器访问这个本地代理。

### Docker backend 示例

```bash
# 终端 1：宿主机上启动 API 反向代理
HTTPS_PROXY="http://corp-proxy.example.com:8080" \
sforge proxy --target https://api.anthropic.com --port 9090

# 终端 2：容器只访问宿主机代理
SFORGE_AGENT_API_BASE_URL="http://host.docker.internal:9090" \
sforge run --task <task> --agent claude-code --disable-internet
```

### Kubernetes backend 提示

Kubernetes Pod 通常不能使用 `host.docker.internal`。如果要配合 `sforge proxy`，需要把代理暴露成 Pod 可访问的地址，例如：

- 宿主机内网 IP:端口
- Kubernetes Service
- LoadBalancer / Ingress

然后设置：

```bash
SFORGE_AGENT_API_BASE_URL="http://<pod-reachable-proxy>:9090" \
sforge run \
  --task <task> \
  --agent claude-code \
  --backend k8s \
  --judge-url http://<pod-reachable-judge>:8080 \
  --disable-internet
```

## 任务作者注意事项

当 `internet: false` 时：

- 所有依赖必须在镜像构建阶段安装（`setup_cmds`）
- 不要要求 Agent 下载依赖、访问外部网页或拉取远程仓库
- Agent 提示词会自动包含网络受限通知
- 建议在 `agent_query` 中说明“所有依赖已预装”

## 常见问题

| 现象 | 可能原因 | 处理方式 |
|------|----------|----------|
| Docker backend 报 iptables 权限错误 | 宿主机没有配置 iptables 免密 sudo | 配置 `sudo -n iptables` 可用，或不要使用 `--disable-internet` |
| Docker backend 下 API 访问失败 | API 域名解析、代理配置或白名单端口不正确 | 检查 `SFORGE_AGENT_API_BASE_URL`，避免直接注入 HTTP/HTTPS proxy |
| Kubernetes backend 下 Pod 仍能访问互联网 | CNI 不支持或未执行 NetworkPolicy | 确认集群 NetworkPolicy 能力，使用测试 Pod 验证 egress 策略 |
| Kubernetes backend 下无法访问 Judge | `--judge-url` 不是 Pod 可访问地址 | 使用 Pod 可访问的内网 IP、Service、Ingress 或 LoadBalancer 地址 |
| Kubernetes backend 下无法访问 AI API | API 域名解析到的 IP 不可达，或需要经过代理 | 使用 Pod 可访问的 API 代理，并把 `SFORGE_AGENT_API_BASE_URL` 指向该代理 |
