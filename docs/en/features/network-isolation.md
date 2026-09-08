---
title: Network Isolation
---

# Network Isolation

Network isolation prevents the agent from directly accessing the internet, allowing the Work container/pod to reach only the required Judge Server and AI API endpoints.

## Usage

```bash
# Disable internet via CLI flag
sforge run --task <task> --agent claude-code --disable-internet

# Disable internet by default in task JSON
{ "internet": false }

# Force enable internet, overriding task JSON
sforge run --task <task> --agent claude-code --enable-internet
```

The implementation of `--disable-internet` depends on the container backend:

| Backend | Implementation |
|---------|----------------|
| Docker | Host-side iptables/ip6tables rules |
| Kubernetes | Kubernetes NetworkPolicy |
| E2B | E2B `update_network` allow/deny rules |

## Allowed Endpoints

When network isolation is enabled, SForge builds an outbound allowlist for the Work container/pod:

- Judge Server URL (`--judge-url`)
- Agent API base URL (`SFORGE_AGENT_API_BASE_URL` or the agent's default API URL)
- DNS (TCP/UDP 53 for the Kubernetes backend)

All other outbound traffic is blocked. Dependency downloads, GitHub access, package registries, and other external resources should be handled during image build.

## Docker Backend

The Docker backend enforces isolation with host-side iptables/ip6tables rules.

### How It Works

- Creates a per-Work-container iptables chain (`SFORGE_<container_id>`)
- Allows TCP only to the Judge Server IP:port and AI API IP:port
- Allows established/related connections
- Drops all other outbound traffic
- Blocks IPv6 entirely
- Drops the `NET_RAW` capability when creating the container
- Cleans up rules automatically when the container stops

### Prerequisites

- Run the Docker backend directly on the host
- `sudo -n iptables` must work, meaning passwordless sudo for iptables
- Cannot be used directly with `SFORGE_HTTP_PROXY` / `SFORGE_HTTPS_PROXY`

If permissions are missing, the run fails with a passwordless sudo for iptables error.

## Kubernetes Backend

The Kubernetes backend enforces egress restrictions with `NetworkPolicy`.

### How It Works

SForge creates one NetworkPolicy for each Work Pod:

- Policy name is like `sforge-iso-<pod-name>`
- The policy selects only the current Work Pod through label `sforge-pod=<pod-name>`
- `policyTypes` includes `Egress`
- Egress allowlist includes:
  - Judge Server IP:port
  - AI API IP:port
  - DNS TCP/UDP 53
- The NetworkPolicy is deleted when the Pod is cleaned up

### Prerequisites

- The cluster CNI must support and enforce Kubernetes NetworkPolicy
- The current kubeconfig must be allowed to create, query, and delete NetworkPolicies
- `--judge-url` must be reachable from pods, such as a private host IP, LoadBalancer, Ingress, or in-cluster Service
- If the API URL is a hostname, SForge resolves it to IPv4 addresses at startup and writes those IPs into the NetworkPolicy

Example:

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --judge-url http://10.0.0.12:8080 \
  --disable-internet
```

::: warning
Whether NetworkPolicy actually blocks traffic depends on the cluster CNI. Some clusters allow NetworkPolicy objects to be created but do not enforce them. Validate isolation with a small task before relying on it.
:::

## E2B Backend

The E2B backend applies the allowlist with the official `update_network` API.
E2B rules operate at host level rather than port level, so allowing a hostname
allows all ports on that host. The E2B API currently accepts the
IPv4 all-traffic selector (`0.0.0.0/0`) and rejects `::/0`; SForge therefore
uses the provider-supported selector rather than sending an invalid IPv6 rule.
The deny rule remains active until the Sandbox is deleted. Generic host proxy
variables are not forwarded to E2B Sandboxes.

## Using with Proxy: `sforge proxy`

Directly injecting `SFORGE_HTTP_PROXY` / `SFORGE_HTTPS_PROXY` into the Work container is incompatible with network isolation. If the AI API must be reached through a corporate proxy, run `sforge proxy` on the host and allow the Work container to reach only that local proxy.

### Docker Backend Example

```bash
# Terminal 1: start API reverse proxy on the host
HTTPS_PROXY="http://corp-proxy.example.com:8080" \
sforge proxy --target https://api.anthropic.com --port 9090

# Terminal 2: container only reaches the host proxy
SFORGE_AGENT_API_BASE_URL="http://host.docker.internal:9090" \
sforge run --task <task> --agent claude-code --disable-internet
```

### Kubernetes Backend Notes

Kubernetes pods usually cannot use `host.docker.internal`. To use `sforge proxy` with k8s, expose the proxy at an address reachable from pods, such as:

- a private host IP and port
- a Kubernetes Service
- a LoadBalancer / Ingress

Then set:

```bash
SFORGE_AGENT_API_BASE_URL="http://<pod-reachable-proxy>:9090" \
sforge run \
  --task <task> \
  --agent claude-code \
  --backend k8s \
  --judge-url http://<pod-reachable-judge>:8080 \
  --disable-internet
```

## Design Notes for Task Authors

When `internet: false`:

- All dependencies must be installed during image build (`setup_cmds`)
- Do not ask the agent to download dependencies, browse external pages, or clone remote repositories
- The agent prompt automatically includes a network restriction notice
- It is recommended to state in `agent_query` that all dependencies are pre-installed

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Docker backend reports an iptables permission error | Host does not have passwordless sudo for iptables | Configure `sudo -n iptables`, or do not use `--disable-internet` |
| Docker backend cannot reach the API | API hostname resolution, proxy config, or allowlisted port is wrong | Check `SFORGE_AGENT_API_BASE_URL`; avoid injecting HTTP/HTTPS proxy directly |
| Kubernetes backend pod can still access the internet | CNI does not support or enforce NetworkPolicy | Confirm NetworkPolicy support and validate egress policy with a test pod |
| Kubernetes backend cannot reach Judge | `--judge-url` is not reachable from pods | Use a pod-reachable private IP, Service, Ingress, or LoadBalancer address |
| Kubernetes backend cannot reach the AI API | API hostname IPs are unreachable, or access must go through a proxy | Use a pod-reachable API proxy and point `SFORGE_AGENT_API_BASE_URL` to it |
