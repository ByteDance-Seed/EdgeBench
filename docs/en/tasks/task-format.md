---
title: Task Format
---

# Task Format

SForge runs benchmarks. A benchmark is a directory, and each task in it is a directory that holds everything about the task in plaintext: prompt, workspace, grader, hidden tests and data. Images are build artifacts made from it.

```
<benchmark>/
  benchmark.toml           # name, image registry, blob URL
  tasks/<task_id>/         # one directory per task
  bases/<name>/Dockerfile  # optional shared toolchain images
```

Pass the directory to SForge with `-b <dir>` or `SFORGE_BENCHMARK`; without either, SForge uses `edgebench/`. [EdgeBench](https://github.com/ByteDance-Seed/EdgeBench/tree/main/edgebench) is in `edgebench/` of this repository; its own rules for tasks (pinning, data limits, `NOTES.md`, status) are in [`edgebench/tasks/SCHEMA.md`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/edgebench/tasks/SCHEMA.md).

## benchmark.toml

```toml
name = "edgebench"               # image names: <name>.{base,work,judge}.<id>:<hash>
registry = "docker.io/seededge"  # optional: where sforge pull and Kubernetes get images
blob_url = "https://github.com/ByteDance-Seed/EdgeBench/releases/download/task-blobs"  # optional, see Blobs
```

## Task Layout

```
tasks/<task_id>/
  task.toml              # metadata and runtime contract
  instruction.md         # the prompt given to the agent
  environment/
    Dockerfile           # work image (build context: the task directory)
    ...                  # workspace files: README, tools, starter code
  judge/
    Dockerfile           # judge image (build context: the task directory)
    ...                  # grader, hidden tests, test data
```

Other files, such as a `NOTES.md` or reference solutions, are ignored by SForge. Images run as root; SForge copies the agent in at run time, so do not install one in the image.

## task.toml

The fields SForge reads; other keys (EdgeBench's `category` or `status`, for example) are free-form metadata.

```toml
id = "ad_placement_optimization"   # must match the directory name
name = "Ad Placement Optimization"
version = "1.0.0"          # bump on any change that can move scores

[environment]
base = "cpp"               # bases/<name>; omit if the Dockerfile uses a public image directly
platform = "linux/amd64"
cwd = "/home/workspace/ad-placement"   # the agent's working directory
internet = false           # may the work container reach the internet?
cpus = 4                   # work container CPU and memory (optional; a run can override them)
memory = "16g"

[submission]
paths = ["solution.cpp"]   # what sforge-submit sends, relative to cwd ("." = everything)
exclude = []               # path prefixes or basename globs to leave out

[judge]
cmd = "bash /judge/run.sh" # run in cwd after the submission is extracted there
timeout_sec = 600
internet = false           # default: the judge container has no network
cpus = 4                   # judge container CPU and memory, as for the work container
memory = "16g"

[score]
direction = "maximize"     # maximize | minimize
rescale = { kind = "piecewise_max", baseline = 0.0, rank30 = 47169682940.0, rank1 = 49702568341.0, super_anchor = 50000000000.0 }

[[blobs]]                  # only for data kept out of git
path = "judge/blobs/hidden.tar.gz"
sha256 = "..."

[game]                     # only for game tasks
server_cmd = "..."
```

`rescale` maps the raw score to 0–100. Kinds include `linear`, `log_max`, `log_min`, `log_anchor`, `piecewise_max`, `piecewise_min` and `piecewise_log_min`; see `sforge/harness/score_rescale.py` for their parameters.

## Judge Contract

- SForge extracts the filtered submission into `cwd` in a fresh judge container and runs `[judge] cmd` there.
- The grader **must** write `/opt/sforge/result.json`:

  ```json
  {"score": 43623268300.0, "valid": true, "summary": "50/50 cases ok",
   "details": [{"name": "case_0000", "status": "PASSED", "score": 1.0}],
   "metrics": {}}
  ```

  `score` is the raw task score, required when `valid` is true. `valid: false` rejects the submission. `summary`, `details` and `metrics` are feedback only.
- stdout and stderr are logs; SForge does not parse them.
- The judge container gets its limits as `SFORGE_CPUS` and `SFORGE_MEMORY` (the work container gets its own). Size parallelism with `SFORGE_CPUS`: under a CPU quota, `nproc` and `os.cpu_count()` report the host's cores.
- No `result.json`, a non-numeric score or a judge timeout makes the submission invalid. A compile error or an empty submission should be a valid score (usually 0) when the grader can state one.
- The best result of a run is the best `score` among valid submissions, in `direction`.

## Images and Bases

Image tags are content hashes computed by SForge, with the benchmark's `name` as prefix:

| Image | Tag hashes |
|-------|------------|
| `<name>.base.<base>:<hash>` | `bases/<base>/` |
| `<name>.work.<id>:<hash>` | `environment/` and the base tag |
| `<name>.judge.<id>:<hash>` | `environment/`, `judge/` and the base tag |

Blobs count by their declared sha256. Editing `task.toml` or `instruction.md` does not rebuild images. Task Dockerfiles that use a base start with `ARG BASE_IMAGE` / `FROM ${BASE_IMAGE}`; `sforge build` builds the base first and passes its tag.

## Blobs

Data too large for git goes into a blob: a tarball listed in `[[blobs]]` with its sha256, kept in the task directory at a gitignored path and `ADD`ed by the Dockerfile. Before building, `sforge build` checks each blob and downloads missing ones from `$SFORGE_BLOB_URL/<sha256>`, else from the benchmark's `blob_url`. A `file://` URL works for a local copy.

## Changing or Adding a Task

```bash
# 1. Edit edgebench/tasks/<task_id>/ (bump version if scores can move)

# 2. Build: base, work and judge images, downloading any blobs
sforge build --task <task_id>

# 3. Grade a submission archive with the new judge
tar -czf sub.tar.gz -C <workspace> .
sforge eval --task <task_id> --archive sub.tar.gz

# 4. Optionally, run an agent on it
sforge run --task <task_id> --agent claude-code --timeout 3600
```

`tools/judge_local.py` runs a judge image directly on an archive, outside the judge server, and prints the result as one JSON line.

For EdgeBench, the steps for reporting and fixing a task problem are in [CONTRIBUTING.md](https://github.com/ByteDance-Seed/EdgeBench/blob/main/CONTRIBUTING.md#fixing-an-edgebench-task), and the task rules in [`edgebench/tasks/SCHEMA.md`](https://github.com/ByteDance-Seed/EdgeBench/blob/main/edgebench/tasks/SCHEMA.md). CI builds the changed images; after merge they are published to Docker Hub (see [Pre-built Images](/en/features/prebuilt-images)).
