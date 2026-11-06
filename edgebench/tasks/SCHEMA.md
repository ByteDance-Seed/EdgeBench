# EdgeBench task rules (schema v0)

EdgeBench tasks use SForge's task format: the layout, `task.toml`, the judge contract
and image tags are described in the
[Task Format](https://bytedance-seed.github.io/EdgeBench/en/tasks/task-format) docs.
This file holds EdgeBench's own rules on top of it. One task = one directory under
`tasks/<task_id>/`, the complete source of truth for the task:

```
tasks/<task_id>/
  task.toml              # metadata + runtime contract
  instruction.md         # prompt given to the agent (was `work.agent_query`)
  environment/           # work image; build context = the task directory
  judge/                 # judge image: grader, hidden tests, test data -- plaintext, committed
  solution/              # optional: reference / baseline solutions
  NOTES.md               # source, deviations from v1, regression summary, known issues
bases/<name>/Dockerfile  # shared base images (toolchains), referenced by tasks
```

## Rules

1. **Self-contained.** Every file that ends up in the work or judge image comes from
   the task directory, a `bases/` image, or a pinned public upstream fetch.
   No private hosts (company domains, private object storage, internal PyPI/npm/maven),
   no tokens, no `.git` directories from source repos.
   Nothing the task ships lives under `/tmp`: grader files go in `/judge/`, workspace
   files at v1's paths. `/opt/sforge/` belongs to the harness (agent bundle, prompt,
   hooks, transfers, `result.json`). Graders may use `mktemp` for scratch at run time.
2. **Pinned.** `FROM` uses a digest (`image@sha256:...`). Every network fetch in a
   Dockerfile is a public URL with a fixed version and a `sha256sum -c` check
   (or a lockfile with hashes for pip/cargo/npm). Mirrors may only speed up
   transport of hash-verified content; they never appear in task files.
3. **Root.** Images run as root (`HOME=/root`). No `agent` user, no sudo.
   Agents (Claude Code / Codex) are injected at runtime by the harness, never baked in.
4. **Big data.** Git holds at most 100 MB of data per task, and no file over 50 MB.
   Anything beyond that is packed into one or a few blobs (deterministic tarballs,
   at most 2 GB each) that are published as GitHub Release assets named by their
   sha256. The blob file sits in the task directory at a gitignored path, is listed
   in `task.toml` `[[blobs]]`, and the Dockerfile `ADD`s it (Docker unpacks .tar.gz /
   .tar.xz). `sforge build` checks every listed blob's sha256 and downloads missing
   ones from `$SFORGE_BLOB_URL/<sha256>` before building (default: `blob_url` in
   `benchmark.toml`, the assets of this repo's `task-blobs` Release; a `file://` URL
   works for a local copy). A new blob is uploaded there in the same change that
   declares it. Pack with
   `tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner -cf - DIR | gzip -n > X.tar.gz`
   (or `xz -T1`) so the hash is reproducible. NOTES.md says what is inside and where it came from.
5. **Fidelity first, then versioned fixes.** Version 1.0.0 of every task reproduces the
   published v1 behaviour, bugs included; suspected bugs are recorded in `NOTES.md` under
   "Known issues". A fix is a pull request that bumps `version` and shows old vs new judge on
   the same submissions (see CONTRIBUTING.md).

## task.toml metadata

Besides the fields SForge reads, every EdgeBench task.toml has:

```toml
schema_version = 0
category = "Combinatorial Optimization"
language = "C++"
description = "one paragraph, from tasks.jsonl"
version = "1.0.0"          # task version; bump on any behaviour change
status = "migrated"        # migrated | migrated-unchecked | verified | deprecated (see Status)
```

`[environment]` and `[judge]` always set `cpus` and `memory`: the official leaderboard setting.
A grader that runs cases in parallel sizes the pool with `SFORGE_CPUS`, not `nproc`.
`[judge] internet = true` only when grading needs it (e.g. an LLM judge); say why in NOTES.md.
Bases pin their `FROM` by digest and apt by a dated snapshot. Proxies reach the build only
as Docker's predefined `http_proxy`/`https_proxy`/`no_proxy` args (set
`SFORGE_HTTP_PROXY`/`SFORGE_HTTPS_PROXY`/`SFORGE_NO_PROXY`).

## Migration rules learned in the pilot

* Reproduce v1's agent-visible workspace exactly and v1's raw score exactly; verify
  both (file sha256 lists, old vs new judge on historical submissions on the same machine).
* Rule 1's "no `.git` from source repos" means clones. If v1 made its own workspace repo
  (`git init && git add -A && git commit -m init`), repeat it with v1's author, email,
  message and dates pinned (`GIT_AUTHOR_DATE`/`GIT_COMMITTER_DATE`) so it is reproducible.
* Time-limited/anytime graders (e.g. AHC) vary with CPU speed: compare old and new
  on the same host, at least twice each, and report the spread.
* Prebuilt tools are rebuilt from committed source when it exists; prove equivalence
  behaviourally when bytes differ.
* Shared toolchains go into a base and are reused, never copied into task layers
  (Lean: link `.lake/packages` to the base's Mathlib).
* Record, don't fix. Grader bugs, score exploits and unclear wording found while
  migrating go under "Known issues" in NOTES.md and later become GitHub issues. Only
  migration bugs are fixed here.

## NOTES.md

Public and short, with these sections:

* **Source**: where each kind of file comes from (public upstream with version and hash,
  or "the task authors' repository (not public)") and how it was checked against v1.
* **Deviations from v1**: every intended difference and why.
* **Regression summary**: old vs new judge on the same submissions, same host, with the
  spread of timed graders, and one sentence on the result.
* **Known issues**: the problem and its impact, and the fix when it is clear. Describe
  exploits by their mechanism; do not publish a ready-made reproducer.
* **Changes** (once there are any): one entry per version after 1.0.0, newest first: what
  changed, why (link the issue), and the effect on scores.

No internal hostnames, paths, people, run ids or private-repo commits.

## Status

* `migrated`: built from this directory, workspace matches v1, and old vs new judge
  agree on historical submissions (within the old image's own spread for timed graders).
* `migrated-unchecked`: built, but the v1 comparison was not possible (no historical
  submissions or no v1 image); NOTES.md says why.
* `verified`: a community review of the task itself found no open blocking issue.
* `deprecated`: kept for history, not run by default.

## Cross-task known issues

1. **Submission code runs as root next to the grader.** Grading a code task means
   running the submission (ad_placement compiles and runs `solution.cpp`; Lean's
   `lake build` runs any `#eval`). Inside the judge container that code is root, so
   it can rewrite whatever the score comes from: `result.json` (a detached process can
   do it after the grader exits), the grader's own files, or the grader's stdout through
   `/proc` (so v1's stdout parsing was not safe either). Examples: ad_placement_optimization
   Known issue 6, lean_analysis_proofs Known issue 1. The host and other submissions
   are not affected (one fresh judge container per submission). Fix per
   task: run untrusted code as an unprivileged user that cannot write the grader's
   files or `/opt/sforge/`.
