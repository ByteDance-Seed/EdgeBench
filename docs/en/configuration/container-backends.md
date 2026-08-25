---
title: Container Backends
---

# Container Backends

SForge uses a container backend to create work and judge environments. The
default backend is local Docker. Use `k8s` for an existing Kubernetes cluster,
or `e2b` for E2B-hosted environments.

## Choosing a Backend

| Backend | Best for | Main requirements |
|---------|----------|-------------------|
| `docker` | Local development, task debugging, single-machine evaluation, small experiments | A working local Docker daemon |
| `k8s` | Shared clusters, high-concurrency batch evaluation, running Work/Judge pods in a cluster | `kubectl` access, images pullable by the cluster, and a Judge URL reachable from pods |
| `e2b` | Remote Work/Judge Sandboxes without operating a cluster | E2B API access, E2B Templates, and a routable Judge Server; see [E2B Backend](#e2b-backend) |

If you are trying a task locally, use the default Docker backend first. The Kubernetes backend is intended for team environments that already have a cluster and container registry.
The E2B backend has a one-time Template preparation step before a new or
changed task image can run.

::: warning Docker backend does not scale to large batches
Each task runs a work container plus ephemeral judge containers, each with its own CPU/memory limits. Running many tasks concurrently on one host (roughly **20+**) causes severe resource contention even on a high-end server. For large batch runs, use the `k8s` backend.
:::

## Configuration

The backend can be configured through CLI flags, environment variables, or experiment YAML:

```bash
# Override for one run
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --judge-url http://10.0.0.12:8080

# Override through environment variables
export SFORGE_BACKEND=k8s
sforge run \
  --task ad_placement_optimization \
  --agent claude-code
```

Experiment YAML can also set the default backend:

```yaml
defaults:
  agent: claude-code
  backend: k8s

tasks:
  ad_placement_optimization: {}
```

## Docker Backend

Docker is the default backend and needs no explicit backend configuration:

```bash
sforge build --task ad_placement_optimization
sforge serve

export SFORGE_AGENT_API_KEY="sk-..."
sforge run \
  --task ad_placement_optimization \
  --agent claude-code
```

The Docker backend:

- uses the local Docker daemon to build and run images
- starts Work containers and Judge containers in local Docker
- uses the default `http://host.docker.internal:8080` so containers can reach the Judge HTTP server on the host
- uses host-side network isolation when `--disable-internet` is enabled

Resource limits can be configured through CLI flags or environment variables:

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --work-cpu-limit 4 \
  --work-mem-limit 8g \
  --judge-cpu-limit 2 \
  --judge-mem-limit 4g
```

## Kubernetes Backend

The Kubernetes backend creates pods through `kubectl`. Each SForge container maps to one Kubernetes Pod with a container named `work`. Pods are labeled with `app=sforge` and `sforge-pod=<pod-name>`.

### Prerequisites

Before using the `k8s` backend, make sure that:

1. `kubectl` is installed locally and can access the target cluster.
2. The target namespace exists, and your kubeconfig can create, query, and delete Pods.
3. Work/Judge images have been pushed to a registry reachable by Kubernetes nodes.
4. The SForge Judge HTTP server is reachable from pods in the cluster.
5. If you use `--disable-internet`, the cluster supports and enforces Kubernetes `NetworkPolicy`.

You can first verify cluster access with:

```bash
kubectl -n <namespace> cluster-info
kubectl -n <namespace> get pods
```

### Kubernetes Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SFORGE_BACKEND` | `docker` | Set to `k8s` to enable the Kubernetes backend |
| `SFORGE_K8S_NAMESPACE` | `default` | Namespace used for Pods and NetworkPolicies |
| `SFORGE_K8S_IMAGE_REGISTRY` | --- | Registry prefix prepended to image names when pods pull images |
| `SFORGE_K8S_KUBECONFIG` | --- | kubeconfig path; if unset, the default `kubectl` configuration is used |
| `SFORGE_K8S_NODE_SELECTOR` | --- | Pod node selector, format: `"key1=val1,key2=val2"` |

### Preparing Images

Kubernetes nodes cannot use images that exist only in your local Docker daemon. With the k8s backend, you usually need to build and push images first:

```bash
# Build images locally
sforge build --task ad_placement_optimization

# Push them to a registry reachable by the cluster
sforge push --task ad_placement_optimization --registry registry.example.com/sforge
```

Then configure the k8s backend to use the same registry prefix:

```bash
export SFORGE_K8S_IMAGE_REGISTRY=registry.example.com/sforge
```

The Kubernetes backend resolves internal image names as:

```text
${SFORGE_K8S_IMAGE_REGISTRY}/<sforge-image-name>:<tag>
```

::: tip
`sforge build` still builds images with local Docker. The `k8s` backend runs Work/Judge pods; it does not build images inside the cluster.
:::

### Judge URL

`--judge-url` is the Judge server address visible from inside the Work container or pod. The Docker default `http://host.docker.internal:8080` is usually only valid for local Docker, not for Kubernetes pods.

For k8s, pass a pod-reachable address with `--judge-url`, such as a host private IP, LoadBalancer, Ingress, or in-cluster Service.

Start the local Judge server with:

```bash
sforge serve --host 0.0.0.0 --port 8080
```

Then run:

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --judge-url http://10.0.0.12:8080
```

### Full Example

```bash
# 1. Build and push images
sforge build --task ad_placement_optimization
sforge push --task ad_placement_optimization --registry registry.example.com/sforge

# 2. Configure the k8s backend
export SFORGE_BACKEND=k8s
export SFORGE_K8S_NAMESPACE=sforge
export SFORGE_K8S_IMAGE_REGISTRY=registry.example.com/sforge
export SFORGE_K8S_KUBECONFIG=$HOME/.kube/config

# Optional: schedule only onto a specific node pool
export SFORGE_K8S_NODE_SELECTOR="pool=sforge"

# 3. Start the Judge server, ensuring pods can reach this address
sforge serve --host 0.0.0.0 --port 8080

# 4. In another terminal, run the agent
export SFORGE_AGENT_API_KEY="sk-..."
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --judge-url http://10.0.0.12:8080
```

### Resource Limits

Work/Judge CPU and memory limits also apply to the k8s backend. SForge converts them to Pod resource requests/limits:

```bash
sforge run \
  --task ad_placement_optimization \
  --agent claude-code \
  --backend k8s \
  --work-cpu-limit 4 \
  --work-mem-limit 8g \
  --judge-cpu-limit 2 \
  --judge-mem-limit 4g
```

Memory formats are converted from Docker style to Kubernetes style, for example `8g` to `8Gi` and `512m` to `512Mi`.

### Network Isolation

With the Docker backend, `--disable-internet` uses host-side network isolation. With the Kubernetes backend, SForge creates a Kubernetes `NetworkPolicy` to restrict pod egress to the Judge server, the configured LLM API endpoint, and DNS.

Notes:

- The cluster CNI must support and enforce `NetworkPolicy`; otherwise the policy may have no effect.
- Your kubeconfig must be allowed to create and delete `NetworkPolicy` resources.
- DNS, egress gateways, and policy implementations differ between clusters, so validate isolation with a small task first.

## E2B Backend

The E2B backend runs Work, Judge, and Game environments as E2B Sandboxes.
The Judge Server itself runs on a host you control, exactly as with the other
backends: start `sforge serve` on a machine the Sandboxes can reach and pass
its address via `--judge-url`.

### Docker Images and E2B Templates

A Docker image and an E2B Template are different runtime objects: E2B
Sandboxes start from Templates, not from Docker image references. Official
E2B Templates for the published EdgeBench tasks are pre-built and published
by the SForge maintainers, so no template preparation step is required.
`sforge run --backend e2b` derives each task image's Template reference
automatically (`edgebench.work.foo_bar:abc123` ->
`edgebench-work-foo-bar:abc123`). Set `SFORGE_E2B_TEMPLATE_MAP` only to
override this mapping, for example to run self-built Templates for a
modified task.

### Run a Task

Start the Judge Server on a host with a publicly routable address (agents
inside E2B Sandboxes submit to it over the internet):

```bash
uv sync --extra e2b
export E2B_API_KEY=...
export SFORGE_ADMIN_SECRET=...   # same value on the serve and run hosts

sforge serve --host 0.0.0.0 --port 8080
```

Then run the agent, pointing `--judge-url` at that host:

```bash
export E2B_API_KEY=...
export SFORGE_ADMIN_SECRET=...   # same value as on the serve host
export SFORGE_AGENT_API_KEY=...
export SFORGE_AGENT_API_BASE_URL=...
export SFORGE_AGENT_MODEL=...

sforge run \
  --backend e2b \
  --task ad_placement_optimization \
  --agent claude-code \
  --judge-url http://YOUR_HOST:8080
```

The Judge Server needs `E2B_API_KEY` too: registrations from an e2b run make
it create Judge and Game Sandboxes on E2B (mirroring how a k8s run makes it
schedule judge pods). Work Sandboxes submit to the Judge Server's public URL;
the Judge Server reaches Game Sandboxes through the E2B service gateway.

Each E2B evaluation is scoped to one task. Supplying multiple task IDs only
batch-schedules several independent evaluations; it does not combine tasks into
one Work or Judge environment. The validation described here invoked one task
per `sforge run` command.

### Plan Limits and Run Sizing

E2B plan limits are part of the runtime contract. Template CPU and memory are
fixed when the Template is built, and requests above the team's limits are
rejected during Template creation. Rebuild the Template with values supported
by the target team; runtime `--work-*` and `--judge-*` flags cannot resize an
existing E2B Template.

Keep the agent timeout comfortably below the team's maximum Sandbox lifetime.
The lifetime must also cover agent installation, archive extraction, pending
Judge evaluations, result collection, and cleanup.

Check each task's `judge.eval_timeout` as well. A Judge Sandbox is subject to
the same team lifetime limit, so a task whose declared evaluator timeout is
longer than that limit cannot be guaranteed to finish when the evaluator uses
its full budget. Do not silently lower the evaluator timeout if leaderboard
comparability matters; use a plan with a sufficient lifetime instead.

Tasks run fully in parallel, so total E2B usage scales with the number of
selected tasks. Budget for the Work Sandboxes, temporary Judge Sandboxes, and
active Game Sandboxes, and leave capacity for overlap while evaluations finish
and resources are cleaned up.

The final score retains SForge's backend-independent semantics: it is the best
result among completed agent and auto-eval submissions. `final_archive.tar.gz`
is a recovery snapshot and is not submitted implicitly at timeout. For short
runs, choose an auto-eval interval that leaves enough time for at least one
evaluation to finish, or have the agent call `sforge-submit` before the run
ends.

### Required User Input

| Input | When required |
| --- | --- |
| `E2B_API_KEY` | E2B runs, on both the `sforge run` host and the Judge Server host |
| A publicly routable `--judge-url` | All E2B runs |
| Agent API key, base URL, and model | Agent runs |

Host `HTTP_PROXY` and `HTTPS_PROXY` variables are not copied into E2B Work,
Judge, or Game Sandboxes. A remote-reachable proxy is forwarded only when the
user explicitly configures `SFORGE_HTTP_PROXY` or `SFORGE_HTTPS_PROXY`; isolated
tasks remove proxy variables entirely. See [Network Isolation](/en/features/network-isolation).

### E2B Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Template not found | The task image version has no published official Template, or the task uses a modified image | Verify the task uses a published image version, or point `SFORGE_E2B_TEMPLATE_MAP` at a self-built Template |
| Agent-side Judge requests intermittently time out | The Work Sandbox could not reach the Judge Server over the internet | Check that the Judge host and port are publicly reachable, then retry the agent submission |
| A run ends at the configured task timeout with `Sandbox not found` | The team-level maximum Sandbox lifetime was reached before final extraction and cleanup | Shorten the agent timeout, reduce multi-wave batch duration, or use a plan with a longer Sandbox lifetime |
| A run leaves a Sandbox | Cleanup failed or the runner was terminated abruptly | Inspect the run log and wait for the configured E2B TTL as the final safeguard |

## Troubleshooting

| Backend | Symptom | Likely cause | Fix |
| --- | --- | --- | --- |
| Kubernetes | `kubectl cluster-info failed` | Wrong kubeconfig, unreachable cluster, or wrong namespace context | Check `kubectl -n <namespace> cluster-info`; set `SFORGE_K8S_KUBECONFIG` and `SFORGE_K8S_NAMESPACE` if needed |
| Kubernetes | Pod never becomes Running | Image pull failure, scheduling failure, or insufficient resources | Run `kubectl -n <namespace> describe pod <pod>` and check events |
| Kubernetes | Pod cannot pull an image | The image is unavailable to cluster nodes, or registry credentials are missing | Run `sforge push`; verify `SFORGE_K8S_IMAGE_REGISTRY`; configure image pull secrets for the namespace |
| Kubernetes | Work cannot reach Judge | The Judge URL is not pod-reachable, or the server is not listening externally | Start `sforge serve` with `--host 0.0.0.0` and pass a pod-reachable IP or Service URL |
| Kubernetes | `--disable-internet` has no effect | CNI does not enforce NetworkPolicy, or permissions are insufficient | Confirm NetworkPolicy support and permissions |
| Kubernetes | Pod remains Pending with a node selector | No nodes match the selector | Check `SFORGE_K8S_NODE_SELECTOR` and node labels |
