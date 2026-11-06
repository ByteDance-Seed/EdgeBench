# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""SForge CLI entry point."""

from __future__ import annotations

import argparse
import concurrent.futures
import copy
import json
import os
import secrets
import signal
import socket
import sys
import threading
import time
from pathlib import Path
from urllib.parse import urlparse

from sforge.harness.config import SForgeConfig, create_backend_from_config, load_config
from sforge.harness.constants import DEFAULT_BENCHMARK_DIR, DEFAULT_EVAL_INTERVAL
from sforge.harness.docker_build import (
    build_all_images,
    pull_all_images,
    push_all_images,
)
from sforge.harness.run_evaluation import judge_submission
from sforge.harness.task_spec import TaskSpec, load_all_tasks, load_task


def _resolve_task(args, config: SForgeConfig) -> TaskSpec:
    """Resolve a single task. Fails if the user passed more than one ID."""
    specs = _resolve_tasks(args, config)
    if len(specs) > 1:
        print(f"Error: this command takes only one --task, got {len(specs)}")
        sys.exit(1)
    return specs[0]


def _resolve_tasks(args, config: SForgeConfig) -> list[TaskSpec]:
    """Resolve one or more tasks by ID, or all tasks with --all."""
    if getattr(args, "all", False):
        specs = load_all_tasks(config.benchmark)
        if not specs:
            print(f"No tasks found in {config.benchmark.root / 'tasks'}")
            sys.exit(1)
        return specs

    if not args.task:
        print("Error: --task or --all is required")
        sys.exit(1)

    raw = args.task
    task_ids = raw if isinstance(raw, list) else [raw]
    specs: list[TaskSpec] = []
    return [_load_task_by_id(config, tid) for tid in task_ids]


def _load_task_by_id(config: SForgeConfig, task_id: str) -> TaskSpec:
    task_toml = config.benchmark.root / "tasks" / task_id / "task.toml"
    if not task_toml.exists():
        print(f"Error: task '{task_id}' not found at {task_toml}")
        sys.exit(1)
    return load_task(task_toml.parent, config.benchmark)


def _for_each_task(task_specs: list[TaskSpec], fn, verb: str) -> None:
    """Run ``fn(spec) -> dict[label, str]`` for every task, in parallel."""
    print(f"{verb} images for {len(task_specs)} task(s)...")
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(task_specs)) as ex:
        futures = {ex.submit(fn, ts): ts for ts in task_specs}
        for fut in concurrent.futures.as_completed(futures):
            ts = futures[fut]
            try:
                parts = "  ".join(f"{k}={v}" for k, v in fut.result().items())
                print(f"  [{ts.task_id}] {parts}")
            except Exception as e:
                print(f"  [{ts.task_id}] FAILED: {e}", file=sys.stderr)
    print("Done.")


def _make_config(args) -> SForgeConfig:
    """Build config from CLI args."""
    overrides = {}
    for key in ("log_dir", "benchmark_dir", "registry", "backend",
                 "work_cpu_limit", "work_mem_limit", "judge_cpu_limit", "judge_mem_limit"):
        val = getattr(args, key, None)
        if val is not None:
            overrides[key] = val
    config = load_config(overrides)
    if hasattr(args, "benchmark_dir"):  # the command works on a benchmark
        try:
            config.benchmark
        except FileNotFoundError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    return config


def _image_registry(config: SForgeConfig) -> str:
    if not config.image_registry:
        print("Error: no image registry: pass --registry or set registry in benchmark.toml", file=sys.stderr)
        sys.exit(1)
    return config.image_registry


# --- Commands ---


def cmd_build(args):
    """Build base + work + judge images from the task directories."""
    config = _make_config(args)
    task_specs = _resolve_tasks(args, config)
    verbose = not args.silent and len(task_specs) == 1

    def _build(ts: TaskSpec) -> dict:
        base, work, judge = build_all_images(
            ts, config, force=args.force_rebuild or args.force_rebuild_with_base,
            force_base=args.force_rebuild_with_base, verbose=verbose,
        )
        return {"base": base or "-", "work": work, "judge": judge}

    _for_each_task(task_specs, _build, "Building")


def cmd_pull(args):
    """Pull work + judge images from the remote registry."""
    config = _make_config(args)
    registry = _image_registry(config)
    _for_each_task(
        _resolve_tasks(args, config),
        lambda ts: {k: "OK" if ok else "FAIL" for k, ok in pull_all_images(ts, registry).items()},
        "Pulling",
    )


def cmd_push(args):
    """Push base + work + judge images to the remote registry."""
    config = _make_config(args)
    registry = _image_registry(config)
    _for_each_task(
        _resolve_tasks(args, config),
        lambda ts: {k: "OK" if ok else "FAIL" for k, ok in push_all_images(ts, registry).items()},
        "Pushing",
    )


def _run_single_task(
    task_spec: TaskSpec,
    args,
    config: SForgeConfig,
    backend,
    run_id: str,
    verbose: bool = False,
    shutdown_event: threading.Event | None = None,
) -> dict | None:
    """Run agent on one task. Returns a summary dict."""
    run_log_dir = config.log_dir / "runs" / run_id / task_spec.task_id

    if not args.agent:
        print("Error: --agent is required")
        sys.exit(1)

    from sforge.harness.agent import create_agent
    from sforge.harness.run_agent import run_agent

    # CLI --effort wins over experiment/env values already on the config.
    if getattr(args, "effort", None):
        config.agent_effort = args.effort

    agent = create_agent(args.agent, config)
    effective_timeout = args.timeout or config.agent_timeout or agent.timeout
    disable_stop_hook = getattr(args, "disable_stop_hook", False)
    disable_auto_eval = getattr(args, "disable_auto_eval", False)
    disable_auto_resume = getattr(args, "disable_auto_resume", False)
    effective_eval_interval = args.eval_interval if args.eval_interval is not None else DEFAULT_EVAL_INTERVAL

    # Resolve internet access: CLI flags override per-task setting
    if getattr(args, "disable_internet", False):
        internet = False
    elif getattr(args, "enable_internet", False):
        internet = True
    else:
        internet = task_spec.internet

    print(f"Running agent '{agent.spec}' on task: {task_spec.task_id}")
    print(f"  Work image:  {task_spec.work_image_key}")
    print(f"  Run ID:      {run_id}")
    print(f"  Timeout:     {effective_timeout}s")
    if args.model or config.agent_model or agent.default_model:
        print(f"  Model:       {args.model or config.agent_model or agent.default_model}")
    if config.agent_effort:
        print(f"  Effort:      {config.agent_effort}")
    if not task_spec.game_mode:
        eval_status = f"{effective_eval_interval}s" if not disable_auto_eval and effective_eval_interval > 0 else "disabled"
        print(f"  Auto-eval:   {eval_status}")
        hook_status = "disabled" if disable_stop_hook or not agent.stop_hook else agent.stop_hook
        print(f"  Stop hook:   {hook_status}")
        resume_status = "disabled" if disable_auto_resume or not agent.resume_cmd else "enabled"
        print(f"  Auto-resume: {resume_status}")
    print(f"  Internet:    {'enabled' if internet else 'disabled (judge + API only)'}")
    max_subs = getattr(args, "max_submissions", None)
    sub_cooldown = getattr(args, "submission_cooldown", None)
    if max_subs is not None:
        print(f"  Max submissions: {max_subs}")
    if sub_cooldown is not None:
        print(f"  Submit cooldown: {sub_cooldown}s")
    if config.work_cpu_limit:
        print(f"  Work CPU:    {config.work_cpu_limit}")
    if config.work_mem_limit:
        print(f"  Work mem:    {config.work_mem_limit}")
    if config.judge_cpu_limit:
        print(f"  Judge CPU:   {config.judge_cpu_limit}")
    if config.judge_mem_limit:
        print(f"  Judge mem:   {config.judge_mem_limit}")
    print(f"  Judge URL:   {args.judge_url}")
    print(f"  Log dir:     {run_log_dir}")
    print(f"  Agent log:   {run_log_dir / 'run_agent.log'}")
    print(f"  Agent output: {run_log_dir / 'agent_output.txt'}")
    print()

    result = run_agent(
        task_spec=task_spec,
        agent=agent,
        config=config,
        backend=backend,
        run_id=run_id,
        model=args.model,
        timeout=args.timeout,
        judge_url=args.judge_url,
        host_judge_url=getattr(args, "host_judge_url", None),
        eval_interval=effective_eval_interval,
        disable_stop_hook=disable_stop_hook,
        disable_auto_eval=disable_auto_eval,
        disable_auto_resume=disable_auto_resume,
        internet=internet,
        verbose=verbose,
        shutdown_event=shutdown_event,
        max_submissions=getattr(args, "max_submissions", None),
        submission_cooldown=getattr(args, "submission_cooldown", None),
    )

    print(f"\nAgent completed in {result.runtime_seconds:.1f}s")
    print(f"  Timed out:        {result.timed_out}")
    if task_spec.game_mode:
        print(f"  Game sessions:    {result.total_rounds}")
        if result.best_score is not None:
            print(f"  Best score:       {result.best_score:.0f}")
    else:
        print(f"  Total rounds:     {result.total_rounds}")
        print(f"  Best score:       {result.best_score}  (0-100: {result.best_score_0_100})")
        print(f"  Best round:       {result.best_round}")
    print(f"  Final archive:    {run_log_dir / 'final_archive.tar.gz'}")

    combined = {
        "agent": agent.spec,
        "task": task_spec.task_id,
        "run_id": run_id,
        "model": args.model or config.agent_model or agent.default_model,
        "effort": config.agent_effort,
        **result.to_dict(),
    }
    (run_log_dir / "final_result.json").write_text(
        json.dumps(combined, indent=2, ensure_ascii=False)
    )
    print()
    print(json.dumps(combined, indent=2, ensure_ascii=False))
    return combined


def _resolve_experiment_tasks(experiment, config: SForgeConfig) -> list[TaskSpec]:
    """Resolve all tasks listed in an experiment config."""
    return [_load_task_by_id(config, task_id) for task_id in experiment.tasks]


def _apply_experiment_overrides(
    task_spec: TaskSpec,
    args,
    base_config: SForgeConfig,
    experiment,
) -> tuple[SForgeConfig, argparse.Namespace]:
    """Apply experiment overrides for a single task, respecting the priority chain.

    Priority (highest to lowest):
      1. CLI flags (args)
      2. experiment.tasks.<task_id>.* (per-task override)
      3. experiment.defaults.* (experiment-level defaults)
      4. task.toml / env vars / SForgeConfig defaults (base_config, original args)
    """
    if experiment is None:
        return copy.deepcopy(base_config), copy.copy(args)

    from sforge.harness.experiment import resolve_task_overrides

    merged = resolve_task_overrides(experiment, task_spec.task_id)

    task_config = copy.deepcopy(base_config)

    # Apply experiment-level model config (single model per experiment)
    model_cfg = experiment.model
    if model_cfg:
        if model_cfg.api_key is not None:
            task_config.agent_api_key = model_cfg.api_key
        if model_cfg.api_base_url is not None:
            task_config.agent_api_base_url = model_cfg.api_base_url
        if model_cfg.model is not None:
            task_config.agent_model = model_cfg.model

    if merged.extra_env:
        task_config.agent_extra_env.update(merged.extra_env)

    task_args = copy.copy(args)

    if task_args.agent is None and merged.agent is not None:
        task_args.agent = merged.agent

    if task_args.model is None and merged.model is not None:
        task_args.model = merged.model

    if getattr(task_args, "effort", None) is None and merged.effort is not None:
        task_config.agent_effort = merged.effort

    if task_args.timeout is None and merged.timeout is not None:
        task_args.timeout = merged.timeout

    if task_args.eval_interval is None and merged.eval_interval is not None:
        task_args.eval_interval = merged.eval_interval

    if not task_args.disable_stop_hook and merged.disable_stop_hook is not None:
        task_args.disable_stop_hook = merged.disable_stop_hook

    if not task_args.disable_auto_eval and merged.disable_auto_eval is not None:
        task_args.disable_auto_eval = merged.disable_auto_eval

    if not getattr(task_args, "disable_auto_resume", False) and getattr(merged, "disable_auto_resume", None) is not None:
        task_args.disable_auto_resume = merged.disable_auto_resume

    if not task_args.disable_internet and not task_args.enable_internet:
        if merged.internet is not None:
            if merged.internet:
                task_args.enable_internet = True
            else:
                task_args.disable_internet = True

    if task_config.work_cpu_limit is None and merged.work_cpu_limit is not None:
        task_config.work_cpu_limit = merged.work_cpu_limit
    if task_config.work_mem_limit is None and merged.work_mem_limit is not None:
        task_config.work_mem_limit = merged.work_mem_limit
    if task_config.judge_cpu_limit is None and merged.judge_cpu_limit is not None:
        task_config.judge_cpu_limit = merged.judge_cpu_limit
    if task_config.judge_mem_limit is None and merged.judge_mem_limit is not None:
        task_config.judge_mem_limit = merged.judge_mem_limit

    if getattr(task_args, "backend", None) is None and merged.backend is not None:
        task_args.backend = merged.backend
        task_config.backend = merged.backend

    if getattr(task_args, "judge_url", None) is None and merged.judge_url is not None:
        task_args.judge_url = merged.judge_url

    if getattr(task_args, "max_submissions", None) is None and merged.max_submissions is not None:
        task_args.max_submissions = merged.max_submissions

    if getattr(task_args, "submission_cooldown", None) is None and merged.submission_cooldown is not None:
        task_args.submission_cooldown = merged.submission_cooldown

    return task_config, task_args


def _effective_config_dict(
    task_spec: TaskSpec,
    args,
    config: SForgeConfig,
) -> dict:
    """Build a JSON-serializable dict of the effective run parameters for a task.

    Captures the fully-resolved config (after CLI + experiment + defaults merging)
    so runs are reproducible.  API keys are redacted.
    """
    agent_name = args.agent or None
    model = args.model or config.agent_model or None
    timeout = args.timeout or config.agent_timeout or None
    eval_interval = args.eval_interval if args.eval_interval is not None else DEFAULT_EVAL_INTERVAL

    if getattr(args, "disable_internet", False):
        internet = False
    elif getattr(args, "enable_internet", False):
        internet = True
    else:
        internet = task_spec.internet

    d: dict = {
        "task_id": task_spec.task_id,
        "agent": agent_name,
        "model": model,
        "effort": getattr(args, "effort", None) or config.agent_effort,
        "timeout": timeout,
        "eval_interval": eval_interval,
        "disable_stop_hook": getattr(args, "disable_stop_hook", False),
        "disable_auto_eval": getattr(args, "disable_auto_eval", False),
        "disable_auto_resume": getattr(args, "disable_auto_resume", False),
        "internet": internet,
        "judge_url": getattr(args, "judge_url", None),
        "work_cpu_limit": config.work_cpu_limit,
        "work_mem_limit": config.work_mem_limit,
        "judge_cpu_limit": config.judge_cpu_limit,
        "judge_mem_limit": config.judge_mem_limit,
        "max_submissions": getattr(args, "max_submissions", None),
        "submission_cooldown": getattr(args, "submission_cooldown", None),
    }
    if config.agent_api_base_url:
        d["api_base_url"] = config.agent_api_base_url
    if config.agent_api_key:
        d["api_key"] = "<redacted>"
    if config.agent_extra_env:
        sensitive_markers = ("KEY", "TOKEN", "SECRET", "PASSWORD", "CREDENTIAL")
        d["extra_env"] = {
            key: (
                "<redacted>"
                if any(marker in key.upper() for marker in sensitive_markers)
                else value
            )
            for key, value in config.agent_extra_env.items()
        }
    if config.e2b_template_namespace:
        d["e2b_template_namespace"] = config.e2b_template_namespace
    return d


def _start_embedded_judge(config: SForgeConfig, backend_name: str, port: int,
                          advertise: str | None):
    """Serve the judge app on a thread of this process.

    Returns ``(server, container_url, host_url)``. The admin secret lives in
    this process only.
    """
    import uvicorn

    from sforge.harness.judge_server import create_app

    if advertise is None:
        if backend_name != "docker":
            print(f"Error: the {backend_name} backend needs --judge-advertise (an address of "
                  "this machine the sandboxes can reach) or an external --judge-url.",
                  file=sys.stderr)
            sys.exit(1)
        advertise = "host.docker.internal"
    os.environ.setdefault("SFORGE_ADMIN_SECRET", secrets.token_urlsafe(32))
    if not port:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.bind(("", 0))
            port = sock.getsockname()[1]
    server = uvicorn.Server(uvicorn.Config(
        create_app(config), host="0.0.0.0", port=port, log_level="warning",
    ))
    threading.Thread(target=server.run, daemon=True, name="sforge-judge").start()
    deadline = time.time() + 60
    while not server.started:
        if time.time() > deadline:
            raise RuntimeError("In-process judge server did not start")
        time.sleep(0.1)
    host = f"[{advertise}]" if ":" in advertise and not advertise.startswith("[") else advertise
    return server, f"http://{host}:{port}", f"http://127.0.0.1:{port}"


def cmd_run(args):
    """Run a coding agent on one or more tasks, optionally auto-evaluate."""
    import shutil
    import uuid

    # Load experiment config first so env vars are injected before _make_config
    experiment = None
    if args.experiment:
        from sforge.harness.experiment import load_experiment

        experiment = load_experiment(Path(args.experiment).resolve())

    base_config = _make_config(args)

    # Apply experiment-level backend/judge_url defaults before creating backend
    if experiment:
        exp_defaults = experiment.defaults
        if exp_defaults.backend and base_config.backend == "docker" and getattr(args, "backend", None) is None:
            base_config.backend = exp_defaults.backend
        if exp_defaults.judge_url and args.judge_url is None:
            args.judge_url = exp_defaults.judge_url

    # Resolve task list
    if args.task:
        task_specs = _resolve_tasks(args, base_config)
    elif experiment:
        task_specs = _resolve_experiment_tasks(experiment, base_config)
    else:
        print("Error: --task or --experiment is required")
        sys.exit(1)

    run_id = args.run_id or uuid.uuid4().hex[:12]
    multi = len(task_specs) > 1
    verbose = not args.silent and not multi

    # --- Resolve per-task overrides upfront and persist configs ---
    run_root = base_config.log_dir / "runs" / run_id
    run_root.mkdir(parents=True, exist_ok=True)

    if experiment and args.experiment:
        shutil.copy2(Path(args.experiment).resolve(), run_root / "experiment.yaml")

    task_runs: list[tuple[TaskSpec, SForgeConfig, argparse.Namespace]] = []
    unified_tasks: dict[str, dict] = {}

    for ts in task_specs:
        task_config, task_args = _apply_experiment_overrides(
            ts, args, base_config, experiment,
        )
        task_runs.append((ts, task_config, task_args))

        cfg_dict = _effective_config_dict(ts, task_args, task_config)
        unified_tasks[ts.task_id] = cfg_dict

        task_log_dir = run_root / ts.task_id
        task_log_dir.mkdir(parents=True, exist_ok=True)
        (task_log_dir / "run_config.json").write_text(
            json.dumps(cfg_dict, indent=2, ensure_ascii=False)
        )

    unified = {
        "run_id": run_id,
        "experiment": args.experiment or None,
        "stagger": args.stagger or (experiment.stagger if experiment else None),
        "tasks": unified_tasks,
    }
    (run_root / "run_config.json").write_text(json.dumps(unified, indent=2, ensure_ascii=False))

    backend_names = {task_config.backend for _, task_config, _ in task_runs}
    if len(backend_names) != 1:
        raise ValueError(
            "A run must use one container backend; resolved backends: "
            + ", ".join(sorted(backend_names))
        )
    base_config.backend = backend_names.pop()
    backend = create_backend_from_config(base_config)
    if backend.backend_name == "e2b" and any(
        urlparse(ta.judge_url).hostname == "host.docker.internal"
        for _, _, ta in task_runs if ta.judge_url
    ):
        print("Error: e2b sandboxes cannot reach host.docker.internal; pass a "
              "routable --judge-url or --judge-advertise.", file=sys.stderr)
        sys.exit(1)

    # Without --judge-url, this process serves the judge for all of its tasks.
    embedded_judge = None
    if not all(ta.judge_url for _, _, ta in task_runs):
        embedded_judge, container_url, host_url = _start_embedded_judge(
            base_config, backend.backend_name, args.judge_port, args.judge_advertise,
        )
        for _, _, ta in task_runs:
            if not ta.judge_url:
                ta.judge_url, ta.host_judge_url = container_url, host_url
        print(f"Judge server: {container_url} (in-process)")

    # Resolve stagger: CLI flag wins over experiment YAML
    stagger = args.stagger
    if stagger is None and experiment and experiment.stagger:
        stagger = experiment.stagger

    if multi:
        print(f"Multi-task run (verbose output disabled, check log files for details)")
        print(f"  Run ID:  {run_id}")
        if experiment:
            print(f"  Experiment: {args.experiment}")
        n = len(task_runs)
        stagger_delay = stagger / n if stagger and n > 1 else 0
        if stagger:
            print(f"  Tasks:   {', '.join(t.task_id for t in task_specs)} (staggered over {stagger}s, {stagger_delay:.1f}s apart)")
        else:
            print(f"  Tasks:   {', '.join(t.task_id for t in task_specs)} (all in parallel)")
        print()

    shutdown_event = threading.Event()

    # SIGTERM (systemd, platforms, `timeout`) gets the same graceful
    # shutdown as Ctrl+C, so containers are stopped and results collected.
    def _shutdown_handler(signum, frame):
        if not shutdown_event.is_set():
            shutdown_event.set()
            print("\nShutting down — stopping containers (further signals are ignored)...")
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        signal.signal(signal.SIGTERM, signal.SIG_IGN)

    old_sigint = signal.signal(signal.SIGINT, _shutdown_handler)
    old_sigterm = signal.signal(signal.SIGTERM, _shutdown_handler)

    def _invoke(ts: TaskSpec, task_config: SForgeConfig, task_args):
        try:
            return ts, _run_single_task(
                ts, task_args, task_config, backend, run_id,
                verbose=verbose, shutdown_event=shutdown_event,
            ), None
        except SystemExit:
            raise
        except Exception as e:
            return ts, None, e

    summaries: list[dict] = []

    try:
        if multi:
            with concurrent.futures.ThreadPoolExecutor(max_workers=len(task_runs)) as ex:
                futures = []
                for i, (ts, tc, ta) in enumerate(task_runs):
                    if i > 0 and stagger_delay > 0:
                        time.sleep(stagger_delay)
                        if shutdown_event.is_set():
                            break
                    futures.append(ex.submit(_invoke, ts, tc, ta))
                for fut in concurrent.futures.as_completed(futures):
                    ts, summary, err = fut.result()
                    if err is not None:
                        print(f"\n[{ts.task_id}] FAILED: {err}", file=sys.stderr)
                        summaries.append({"task": ts.task_id, "error": str(err)})
                    elif summary is not None:
                        summaries.append(summary)
        else:
            ts, tc, ta = task_runs[0]
            _, summary, err = _invoke(ts, tc, ta)
            if err is not None:
                raise err
            if summary is not None:
                summaries.append(summary)
    except KeyboardInterrupt:
        if not shutdown_event.is_set():
            shutdown_event.set()
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        print("\nShutting down — stopping containers...")
    finally:
        signal.signal(signal.SIGINT, old_sigint)
        signal.signal(signal.SIGTERM, old_sigterm)
        if embedded_judge is not None:
            embedded_judge.should_exit = True

    if multi:
        run_root = base_config.log_dir / "runs" / run_id
        summary_path = run_root / "summary.json"
        summary_path.write_text(json.dumps({
            "run_id": run_id,
            "tasks": summaries,
        }, indent=2, ensure_ascii=False))

        print(f"\n=== Multi-task summary ({len(task_specs)} tasks) ===")
        for s in summaries:
            tid = s.get("task", "?")
            if "error" in s:
                mark = f"ERROR: {s['error']}"
            elif s.get("best_score_0_100") is not None:
                mark = f"{s['best_score_0_100']:.2f}  (raw {s.get('best_score')})"
            else:
                mark = "-"
            print(f"  {tid:<30} {mark}")
        print(f"\nSummary saved: {summary_path}")


def cmd_eval(args):
    """Submit an archive for evaluation."""
    import uuid

    config = _make_config(args)
    task_spec = _resolve_task(args, config)
    backend = create_backend_from_config(config)

    # Read archive
    if args.archive == "-":
        archive_bytes = sys.stdin.buffer.read()
    else:
        archive_path = Path(args.archive)
        if not archive_path.exists():
            print(f"Error: archive file not found: {args.archive}")
            sys.exit(1)
        archive_bytes = archive_path.read_bytes()

    run_id = args.run_id or uuid.uuid4().hex[:12]
    submissions_root = (
        config.log_dir / "runs" / run_id / task_spec.task_id / "submissions"
    )
    submissions_root.mkdir(parents=True, exist_ok=True)

    # Pick the next available manual-N subdir so repeated runs with the same
    # --run-id don't silently overwrite prior results.
    existing = [p.name for p in submissions_root.iterdir() if p.is_dir()]
    n = 1
    while f"manual-{n}" in existing:
        n += 1
    sub_log_dir = submissions_root / f"manual-{n}"

    print(f"Evaluating archive for task: {task_spec.task_id}")
    print(f"  Archive size: {len(archive_bytes)} bytes")
    print(f"  Run ID:       {run_id}")
    print(f"  Log dir:      {sub_log_dir}")
    print()

    report = judge_submission(
        task_spec=task_spec,
        archive=archive_bytes,
        config=config,
        backend=backend,
        submission_id=run_id,
        timeout=args.timeout,
        log_dir=sub_log_dir,
        verbose=not args.silent,
    )

    print()
    print(f"Results:")
    print(f"  Valid:       {report.valid}")
    print(f"  Score:       {report.score}")
    print(f"  Score 0-100: {report.score_0_100}")
    if report.summary:
        print(f"  Summary:     {report.summary}")
    if report.error:
        print(f"  Error:       {report.error}")
    print(f"  Runtime:     {report.runtime_seconds:.2f}s")
    print(f"  Timed out:   {report.timed_out}")

    if args.json:
        print()
        print(json.dumps(report.to_dict(), indent=2, ensure_ascii=False))


def cmd_serve(args):
    """Start the judge HTTP server."""
    config = _make_config(args)

    import uvicorn

    from sforge.harness.judge_server import create_app

    app = create_app(config)
    print(f"Starting SForge judge server on port {args.port}")
    uvicorn.run(app, host=args.host, port=args.port)


def cmd_viewer(args):
    """Start the run viewer (score curves, submissions, token usage)."""
    import uvicorn

    from sforge.viewer import create_app

    config = _make_config(args)
    runs_dir = Path(args.runs_dir).resolve() if args.runs_dir else config.log_dir / "runs"
    print(f"Runs: {runs_dir}")
    print(f"Open: http://{args.host}:{args.port}/")
    uvicorn.run(create_app(runs_dir), host=args.host, port=args.port, log_level="warning")


def cmd_replay(args):
    """Open a run's archived session in the agent's own UI."""
    from sforge.replay import replay

    config = _make_config(args)
    runs_dir = Path(args.runs_dir).resolve() if args.runs_dir else config.log_dir / "runs"
    task_dir = runs_dir / args.run_id / args.task
    if not task_dir.is_dir():
        print(f"Error: no run at {task_dir}", file=sys.stderr)
        sys.exit(1)
    replay(task_dir, args.session)


def cmd_list(args):
    """List available tasks."""
    import unicodedata

    def _display_width(s: str) -> int:
        w = 0
        for ch in s:
            w += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
        return w

    def _pad(s: str, width: int) -> str:
        return s + " " * (width - _display_width(s))

    config = _make_config(args)
    tasks = load_all_tasks(config.benchmark)

    if not tasks:
        print(f"No tasks found in {config.benchmark.root / 'tasks'}")
        return

    col_id = max(_display_width("ID"), max(_display_width(t.task_id) for t in tasks)) + 2
    col_name = max(_display_width("Name"), max(_display_width(t.name) for t in tasks)) + 2
    col_base = max(_display_width("Base"), max(_display_width(t.base or "-") for t in tasks)) + 2

    print(f"{_pad('ID', col_id)} {_pad('Name', col_name)} {_pad('Base', col_base)} Version")
    print("-" * (col_id + col_name + col_base + 10))
    for t in tasks:
        print(f"{_pad(t.task_id, col_id)} {_pad(t.name, col_name)} {_pad(t.base or '-', col_base)} {t.version}")



# --- Main parser ---


def main():
    parser = argparse.ArgumentParser(
        prog="sforge",
        description="SForge: Evaluation harness for coding agents",
    )

    # Global flags
    parser.add_argument("--log-dir", dest="log_dir", default=None)
    parser.add_argument("--silent", action="store_true", default=False,
                        help="Suppress detailed log output (auto-enabled for multi-task runs)")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # Commands that work on tasks take the benchmark directory.
    bench = argparse.ArgumentParser(add_help=False)
    bench.add_argument("-b", "--benchmark", dest="benchmark_dir", default=None, metavar="DIR",
                       help=f"Benchmark directory with benchmark.toml (default: SFORGE_BENCHMARK, else {DEFAULT_BENCHMARK_DIR})")

    # build
    p_build = subparsers.add_parser("build", parents=[bench], help="Build work + judge images")
    p_build_group = p_build.add_mutually_exclusive_group(required=True)
    p_build_group.add_argument("--task", nargs="+",
                               help="One or more task IDs (e.g. --task minitorch gitlet)")
    p_build_group.add_argument("--all", action="store_true", default=False,
                               help="Build images for all tasks")
    p_build.add_argument("--force-rebuild", action="store_true", default=False,
                         help="Force rebuild work + judge images (skip base)")
    p_build.add_argument("--force-rebuild-with-base", action="store_true", default=False,
                         help="Force rebuild ALL images including base")
    p_build.set_defaults(func=cmd_build)

    # pull
    p_pull = subparsers.add_parser("pull", parents=[bench], help="Pull pre-built images from remote registry")
    p_pull_group = p_pull.add_mutually_exclusive_group(required=True)
    p_pull_group.add_argument("--task", nargs="+",
                              help="One or more task IDs")
    p_pull_group.add_argument("--all", action="store_true", default=False,
                              help="Pull images for all tasks")
    p_pull.add_argument("--registry", dest="registry", default=None,
                        help="Registry prefix (default: SFORGE_REGISTRY, else the benchmark's registry)")
    p_pull.set_defaults(func=cmd_pull)

    # push
    p_push = subparsers.add_parser("push", parents=[bench], help="Push built images to remote registry")
    p_push_group = p_push.add_mutually_exclusive_group(required=True)
    p_push_group.add_argument("--task", nargs="+",
                              help="One or more task IDs")
    p_push_group.add_argument("--all", action="store_true", default=False,
                              help="Push images for all tasks")
    p_push.add_argument("--registry", dest="registry", default=None,
                        help="Registry prefix (default: SFORGE_REGISTRY, else the benchmark's registry)")
    p_push.set_defaults(func=cmd_push)

    # run
    p_run = subparsers.add_parser("run", parents=[bench], help="Run an agent on one or more tasks")
    p_run.add_argument("--backend", choices=["docker", "k8s", "e2b"], default=None,
                       help="Container backend (default: docker)")
    p_run.add_argument("--task", default=None, nargs="+",
                       help="One or more task IDs (e.g. --task ahc056 ahc057). "
                            "Multiple tasks are run fully in parallel.")
    p_run.add_argument("--experiment", default=None,
                       help="Path to experiment YAML config file (model config + per-task overrides)")
    p_run.add_argument("--agent", default=None, help="Agent name (claude-code, codex, opencode)")
    p_run.add_argument("--model", default=None, help="Model override")
    p_run.add_argument("--effort", default=None,
                       choices=["low", "medium", "high", "max"],
                       help="Reasoning effort; each agent translates to its native "
                            "mechanism (claude-code env, codex/opencode config). "
                            "Default: agent's own default")
    p_run.add_argument("--timeout", type=int, default=None, help="Agent timeout in seconds")
    p_run.add_argument("--eval-interval", type=int, default=None, help=f"Auto-eval interval in seconds (default {DEFAULT_EVAL_INTERVAL})")
    p_run.add_argument("--disable-auto-eval", action="store_true", default=False,
                       dest="disable_auto_eval", help="Disable background auto-evaluation daemon")
    p_run.add_argument("--disable-stop-hook", action="store_true", default=False,
                       dest="disable_stop_hook", help="Disable the agent stop hook (agent can exit normally)")
    p_run.add_argument("--disable-auto-resume", action="store_true", default=False,
                       dest="disable_auto_resume", help="Disable auto-resume on abnormal agent exit")
    p_run.add_argument("--max-submissions", type=int, default=None, dest="max_submissions",
                       help="Maximum number of agent submissions per run (default: unlimited)")
    p_run.add_argument("--submission-cooldown", type=int, default=None, dest="submission_cooldown",
                       help="Minimum seconds between agent submissions (default: no cooldown)")
    p_run.add_argument("--stagger", type=int, default=None, dest="stagger",
                       help="Spread task launches evenly over N seconds (e.g. --stagger 300)")
    p_run.add_argument("--judge-url", default=None,
                       help="Use an external judge server (`sforge serve`) at this URL. "
                            "By default `run` serves the judge itself.")
    p_run.add_argument("--judge-port", type=int, default=0, dest="judge_port",
                       help="Port for the in-process judge (default: any free port)")
    p_run.add_argument("--judge-advertise", default=None, dest="judge_advertise",
                       help="Host/IP the sandboxes use to reach this machine's in-process judge "
                            "(default: host.docker.internal; required for k8s/e2b)")
    p_run.add_argument("--run-id", default=None, help="Run ID for tracking")
    net_group = p_run.add_mutually_exclusive_group()
    net_group.add_argument(
        "--disable-internet", action="store_true", default=False,
        dest="disable_internet",
        help="Force all tasks to run without internet (only judge server + API allowed). "
             "Requires sudo iptables access.",
    )
    net_group.add_argument(
        "--enable-internet", action="store_true", default=False,
        dest="enable_internet",
        help="Force all tasks to run with full internet access (overrides per-task setting).",
    )
    p_run.add_argument("--work-cpu-limit", type=int, default=None, dest="work_cpu_limit",
                        help="Number of CPUs for work containers (e.g. 4)")
    p_run.add_argument("--work-mem-limit", default=None, dest="work_mem_limit",
                        help="Memory limit for work containers (e.g. '8g', '4096m')")
    p_run.add_argument("--judge-cpu-limit", type=int, default=None, dest="judge_cpu_limit",
                        help="Number of CPUs for judge containers (e.g. 2)")
    p_run.add_argument("--judge-mem-limit", default=None, dest="judge_mem_limit",
                        help="Memory limit for judge containers (e.g. '4g')")
    p_run.set_defaults(func=cmd_run)

    # eval
    p_eval = subparsers.add_parser("eval", parents=[bench], help="Evaluate an archive")
    p_eval.add_argument("--backend", choices=["docker", "k8s", "e2b"], default=None,
                        help="Container backend (default: docker)")
    p_eval.add_argument("--task", required=True, help="Task ID")
    p_eval.add_argument("--archive", required=True, help="Path to .tar.gz archive (or - for stdin)")
    p_eval.add_argument("--run-id", default=None, help="Submission/run ID")
    p_eval.add_argument("--timeout", type=int, default=None, help="Eval timeout in seconds")
    p_eval.add_argument("--judge-cpu-limit", type=int, default=None, dest="judge_cpu_limit",
                        help="Number of CPUs for judge container (e.g. 2)")
    p_eval.add_argument("--judge-mem-limit", default=None, dest="judge_mem_limit",
                        help="Memory limit for judge container (e.g. '4g')")
    p_eval.add_argument("--json", action="store_true", help="Also output JSON report")
    p_eval.set_defaults(func=cmd_eval)

    # serve
    p_serve = subparsers.add_parser("serve", parents=[bench], help="Start judge HTTP server")
    p_serve.add_argument("--host", default="0.0.0.0")
    p_serve.add_argument("--port", type=int, default=8080)
    p_serve.set_defaults(func=cmd_serve)

    # viewer
    p_viewer = subparsers.add_parser("viewer", help="Start the run viewer web UI")
    p_viewer.add_argument("--runs-dir", default=None, help="Run folders (default: <log dir>/runs)")
    p_viewer.add_argument("--host", default="127.0.0.1")
    p_viewer.add_argument("--port", type=int, default=8000)
    p_viewer.set_defaults(func=cmd_viewer)

    # replay
    p_replay = subparsers.add_parser("replay", help="Open a run's agent session in the agent's own UI")
    p_replay.add_argument("--run-id", required=True)
    p_replay.add_argument("--task", required=True)
    p_replay.add_argument("--session", default=None, help="Session id (default: the latest one)")
    p_replay.add_argument("--runs-dir", default=None, help="Run folders (default: <log dir>/runs)")
    p_replay.set_defaults(func=cmd_replay)

    # list
    p_list = subparsers.add_parser("list", parents=[bench], help="List available tasks")
    p_list.set_defaults(func=cmd_list)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
