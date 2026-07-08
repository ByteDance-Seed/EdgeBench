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
import signal
import sys
import threading
import time
from pathlib import Path

import docker

from sforge.harness.config import SForgeConfig, create_backend_from_config, load_config
from sforge.harness.constants import DEFAULT_EVAL_INTERVAL
from sforge.harness.docker_build import (
    build_all_images,
    build_work_image,
    build_judge_image,
    pull_all_images,
    push_all_images,
)
from sforge.harness.docker_utils import cleanup_container
from sforge.harness.run_evaluation import judge_submission
from sforge.harness.benchmark import load_benchmark
from sforge.harness.task_spec import TaskSpec, make_task_spec, load_all_tasks


def _resolve_task(args, config: SForgeConfig) -> TaskSpec:
    """Resolve a single task. Fails if the user passed more than one ID."""
    specs = _resolve_tasks(args, config)
    if len(specs) > 1:
        print(f"Error: this command takes only one --task, got {len(specs)}")
        sys.exit(1)
    return specs[0]


def _resolve_tasks(args, config: SForgeConfig) -> list[TaskSpec]:
    """Resolve one or more tasks by ID, or all tasks with --all."""
    tasks_dir = config.tasks_dir
    benchmark = load_benchmark(tasks_dir)

    if getattr(args, "all", False):
        specs = load_all_tasks(tasks_dir, benchmark)
        if not specs:
            print(f"No tasks found in {tasks_dir}")
            sys.exit(1)
        return specs

    if not args.task:
        print("Error: --task or --all is required")
        sys.exit(1)

    raw = args.task
    task_ids = raw if isinstance(raw, list) else [raw]
    specs: list[TaskSpec] = []
    for tid in task_ids:
        task_file = tasks_dir / f"{tid}.json"
        if not task_file.exists():
            print(f"Error: task '{tid}' not found at {task_file}")
            sys.exit(1)
        specs.append(make_task_spec(task_file, benchmark))
    return specs


def _make_config(args) -> SForgeConfig:
    """Build config from CLI args."""
    overrides = {}
    for key in ("log_dir", "tasks_dir", "registry", "backend",
                 "work_cpu_limit", "work_mem_limit", "judge_cpu_limit", "judge_mem_limit"):
        val = getattr(args, key, None)
        if val is not None:
            overrides[key] = val
    return load_config(overrides)


# --- Commands ---


def cmd_build(args):
    """Build work + judge images for one or more tasks (parallel)."""
    config = _make_config(args)
    task_specs = _resolve_tasks(args, config)
    client = docker.from_env()
    verbose = not args.silent and len(task_specs) == 1

    force_rebuild = args.force_rebuild or args.force_rebuild_with_base
    force_rebuild_base = args.force_rebuild_with_base

    if args.kits_dir:
        _build_from_kits(args, config, task_specs, client,
                         force_rebuild, force_rebuild_base, verbose)
        return

    if len(task_specs) == 1:
        task_spec = task_specs[0]
        print(f"Building images for task: {task_spec.task_id}")
        base, work, judge = build_all_images(
            task_spec, config, client, force_rebuild=force_rebuild,
            force_rebuild_base=force_rebuild_base,
            verbose=verbose,
        )
        print(f"  Base:  {base}")
        print(f"  Work:  {work}")
        print(f"  Judge: {judge}")
    else:
        print(f"Building images for {len(task_specs)} tasks in parallel...")
        print(f"  (verbose output disabled for multi-task build, use single task or check log files)")

        def _build_one(ts: TaskSpec):
            base, work, judge = build_all_images(
                ts, config, client, force_rebuild=force_rebuild,
                force_rebuild_base=force_rebuild_base,
            )
            return ts.task_id, base, work, judge

        with concurrent.futures.ThreadPoolExecutor(max_workers=len(task_specs)) as ex:
            futures = {ex.submit(_build_one, ts): ts for ts in task_specs}
            for fut in concurrent.futures.as_completed(futures):
                ts = futures[fut]
                try:
                    task_id, base, work, judge = fut.result()
                    print(f"  [{task_id}] OK  base={base}  work={work}  judge={judge}")
                except Exception as e:
                    print(f"  [{ts.task_id}] FAILED: {e}", file=sys.stderr)

    print("Done.")


def _build_from_kits(args, config, task_specs, client,
                     force_rebuild, force_rebuild_base, verbose):
    """Build task images from pre-exported build kits instead of setup_cmds."""
    from sforge.harness.kits import build_task_images_from_kits

    kits_root = Path(args.kits_dir)
    verify = args.verify
    print(f"Building {len(task_specs)} task(s) from kits at {kits_root}"
          + (" (with verification)" if verify else ""))

    def _build_one(ts: TaskSpec):
        return ts.task_id, *build_task_images_from_kits(
            ts, kits_root, config, client,
            force_rebuild=force_rebuild, force_rebuild_base=force_rebuild_base,
            verify=verify, verbose=verbose,
        )

    failed = False
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, len(task_specs))) as ex:
        futures = {ex.submit(_build_one, ts): ts for ts in task_specs}
        for fut in concurrent.futures.as_completed(futures):
            ts = futures[fut]
            try:
                task_id, base, work, judge = fut.result()
                print(f"  [{task_id}] OK  base={base}  work={work}  judge={judge}"
                      + ("  verified" if verify else ""))
            except Exception as e:
                failed = True
                print(f"  [{ts.task_id}] FAILED: {e}", file=sys.stderr)
    if failed:
        sys.exit(1)
    print("Done.")


def cmd_pull(args):
    """Pull pre-built images from a remote registry (parallel)."""
    config = _make_config(args)
    if not config.registry:
        print("Error: --registry or SFORGE_REGISTRY env var required for pull")
        sys.exit(1)

    task_specs = _resolve_tasks(args, config)
    client = docker.from_env()

    if len(task_specs) == 1:
        task_spec = task_specs[0]
        print(f"Pulling images for task: {task_spec.task_id}")
        print(f"  Registry: {config.registry}")
        print(f"  Work:  {task_spec.work_image_key}")
        print(f"  Judge: {task_spec.judge_image_key}")
        base_ok, work_ok, judge_ok = pull_all_images(
            task_spec, config.registry, client
        )
        print(f"  Base:  {'OK' if base_ok else 'FAILED'}")
        print(f"  Work:  {'OK' if work_ok else 'FAILED'}")
        print(f"  Judge: {'OK' if judge_ok else 'FAILED'}")
    else:
        print(f"Pulling images for {len(task_specs)} tasks in parallel...")
        print(f"  Registry: {config.registry}")

        def _pull_one(ts: TaskSpec):
            base_ok, work_ok, judge_ok = pull_all_images(
                ts, config.registry, client
            )
            return ts.task_id, base_ok, work_ok, judge_ok

        with concurrent.futures.ThreadPoolExecutor(max_workers=len(task_specs)) as ex:
            futures = {ex.submit(_pull_one, ts): ts for ts in task_specs}
            for fut in concurrent.futures.as_completed(futures):
                ts = futures[fut]
                try:
                    task_id, base_ok, work_ok, judge_ok = fut.result()
                    status = "OK" if all([base_ok, work_ok, judge_ok]) else "PARTIAL"
                    print(f"  [{task_id}] {status}  base={'OK' if base_ok else 'FAIL'}  work={'OK' if work_ok else 'FAIL'}  judge={'OK' if judge_ok else 'FAIL'}")
                except Exception as e:
                    print(f"  [{ts.task_id}] FAILED: {e}", file=sys.stderr)

    print("Done.")


def cmd_push(args):
    """Push locally-built images to the remote registry (parallel)."""
    config = _make_config(args)
    if not config.registry:
        print("Error: --registry or SFORGE_REGISTRY env var required for push")
        sys.exit(1)

    task_specs = _resolve_tasks(args, config)
    client = docker.from_env()

    if len(task_specs) == 1:
        task_spec = task_specs[0]
        print(f"Pushing images for task: {task_spec.task_id}")
        print(f"  Registry: {config.registry}")
        print(f"  Base hash:  {task_spec.base_image_hash[:12]}")
        print(f"  Work hash:  {task_spec.work_image_hash[:12]}")
        print(f"  Judge hash: {task_spec.judge_image_hash[:12]}")
        base_ok, work_ok, judge_ok = push_all_images(
            task_spec, config.registry, client
        )
        print(f"  Base:  {'OK' if base_ok else 'FAILED'}")
        print(f"  Work:  {'OK' if work_ok else 'FAILED'}")
        print(f"  Judge: {'OK' if judge_ok else 'FAILED'}")
    else:
        print(f"Pushing images for {len(task_specs)} tasks in parallel...")
        print(f"  Registry: {config.registry}")

        def _push_one(ts: TaskSpec):
            base_ok, work_ok, judge_ok = push_all_images(
                ts, config.registry, client
            )
            return ts.task_id, base_ok, work_ok, judge_ok

        with concurrent.futures.ThreadPoolExecutor(max_workers=len(task_specs)) as ex:
            futures = {ex.submit(_push_one, ts): ts for ts in task_specs}
            for fut in concurrent.futures.as_completed(futures):
                ts = futures[fut]
                try:
                    task_id, base_ok, work_ok, judge_ok = fut.result()
                    status = "OK" if all([base_ok, work_ok, judge_ok]) else "PARTIAL"
                    print(f"  [{task_id}] {status}  base={'OK' if base_ok else 'FAIL'}  work={'OK' if work_ok else 'FAIL'}  judge={'OK' if judge_ok else 'FAIL'}")
                except Exception as e:
                    print(f"  [{ts.task_id}] FAILED: {e}", file=sys.stderr)

    print("Done.")



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

    print(f"Running agent '{agent.name}' on task: {task_spec.task_id}")
    print(f"  Work image:  {task_spec.work_image_key}")
    print(f"  Run ID:      {run_id}")
    print(f"  Timeout:     {effective_timeout}s")
    if args.model or config.agent_model or agent.default_model:
        print(f"  Model:       {args.model or config.agent_model or agent.default_model}")
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
        print(f"  Best pass rate:   {result.best_pass_rate:.2%}")
        if result.best_score is not None:
            print(f"  Best score:       {result.best_score:.0f}")
        print(f"  Best round:       {result.best_round}")
    print(f"  Final archive:    {run_log_dir / 'final_archive.tar.gz'}")

    combined = {
        "agent": agent.name,
        "task": task_spec.task_id,
        "run_id": run_id,
        "model": args.model or config.agent_model or agent.default_model,
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
    tasks_dir = config.tasks_dir
    benchmark = load_benchmark(tasks_dir)
    specs: list[TaskSpec] = []
    for task_id in experiment.tasks:
        task_file = tasks_dir / f"{task_id}.json"
        if not task_file.exists():
            print(f"Error: task '{task_id}' (from experiment config) not found at {task_file}")
            sys.exit(1)
        specs.append(make_task_spec(task_file, benchmark))
    return specs


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
      4. task JSON / env vars / SForgeConfig defaults (base_config, original args)
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

    if getattr(task_args, "judge_url", None) == "http://host.docker.internal:8080" and merged.judge_url is not None:
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
        d["api_key"] = config.agent_api_key[:8] + "..."
    if config.agent_extra_env:
        d["extra_env"] = config.agent_extra_env
    return d


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
        from sforge.harness.experiment import resolve_task_overrides
        exp_defaults = experiment.defaults
        if exp_defaults.backend and base_config.backend == "docker" and getattr(args, "backend", None) is None:
            base_config.backend = exp_defaults.backend
        if exp_defaults.judge_url and args.judge_url == "http://host.docker.internal:8080":
            args.judge_url = exp_defaults.judge_url

    # Resolve task list
    if args.task:
        task_specs = _resolve_tasks(args, base_config)
    elif experiment:
        task_specs = _resolve_experiment_tasks(experiment, base_config)
    else:
        print("Error: --task or --experiment is required")
        sys.exit(1)

    backend = create_backend_from_config(base_config)

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

    def _sigint_handler(signum, frame):
        if not shutdown_event.is_set():
            shutdown_event.set()
            print("\nShutting down — stopping containers (Ctrl+C again has no effect)...")
        signal.signal(signal.SIGINT, signal.SIG_IGN)

    old_sigint = signal.signal(signal.SIGINT, _sigint_handler)

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
            elif "best_pass_rate" in s:
                mark = f"{s['best_pass_rate']:.2%}"
                if s.get("best_score") is not None:
                    mark += f"  (score {s['best_score']:.0f})"
            elif "eval" in s and s["eval"]:
                mark = f"{s['eval'].get('pass_rate', 0):.2%}"
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
    print(f"  Total tests: {report.total_tests}")
    print(f"  Passed:      {report.passed}")
    print(f"  Failed:      {report.failed}")
    print(f"  Errors:      {report.errors}")
    print(f"  Pass rate:   {report.pass_rate:.2%}")
    if report.score_0_100 is not None:
        print(f"  Score 0-100: {report.score_0_100:.2f}")
    print(f"  Runtime:     {report.runtime_seconds:.2f}s")
    print(f"  Timed out:   {report.timed_out}")

    if args.json:
        print()
        print(json.dumps(report.to_dict(), indent=2, ensure_ascii=False))


def cmd_serve(args):
    """Start the judge HTTP server."""
    config = _make_config(args)

    from sforge.harness.judge_server import create_app
    import uvicorn

    app = create_app(config)
    print(f"Starting SForge judge server on port {args.port}")
    uvicorn.run(app, host=args.host, port=args.port)


def cmd_proxy(args):
    """Start a local API reverse proxy (for use with --disable-internet)."""
    config = _make_config(args)

    http_proxy = config.http_proxy
    https_proxy = config.https_proxy
    if not http_proxy and not https_proxy:
        print(
            "ERROR: No proxy configured. Set SFORGE_HTTPS_PROXY (or HTTPS_PROXY) "
            "before starting the proxy.",
            file=sys.stderr,
        )
        sys.exit(1)

    from sforge.harness.api_proxy import APIProxy

    proxy = APIProxy(
        target_url=args.target,
        http_proxy=http_proxy,
        https_proxy=https_proxy,
        host=args.host,
        port=args.port,
    )
    print(f"Starting API proxy on {proxy.local_url}")
    print(f"  Forwarding to: {proxy.target_url}")
    print(f"  Via proxy:     {https_proxy or http_proxy}")
    print()
    print("Usage: in another terminal, run:")
    print(f"  export SFORGE_AGENT_API_BASE_URL=http://host.docker.internal:{proxy.port}")
    print(f"  python -m sforge run --task <TASK> --agent <AGENT> --disable-internet")
    print()
    proxy.run_forever()


def cmd_visualizer(args):
    """Start the run-results visualizer web UI."""
    from sforge.visualizer.server import create_app as create_viz_app
    import uvicorn

    config = _make_config(args)
    runs_dir = Path(args.runs_dir).resolve()
    tasks_dir = Path(args.tasks_dir).resolve() if args.tasks_dir else config.tasks_dir
    if not tasks_dir.is_dir():
        tasks_dir = None
    if not runs_dir.is_dir():
        print(f"WARNING: runs dir does not exist: {runs_dir}")
    else:
        n = sum(1 for p in runs_dir.iterdir() if p.is_dir())
        print(f"Found {n} run folder(s) in {runs_dir}")
    print(f"Reading tasks from: {tasks_dir if tasks_dir else '(none)'}")
    app = create_viz_app(runs_dir, tasks_dir=tasks_dir)
    print(f"Open: http://{args.host}:{args.port}/")
    uvicorn.run(app, host=args.host, port=args.port)


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
    benchmark = load_benchmark(config.tasks_dir)
    tasks = load_all_tasks(config.tasks_dir, benchmark)

    if not tasks:
        print(f"No tasks found in {config.tasks_dir}")
        return

    col_id = max(_display_width("ID"), max(_display_width(t.task_id) for t in tasks)) + 2
    col_name = max(_display_width("Name"), max(_display_width(t.name) for t in tasks)) + 2
    col_base = max(_display_width("Base Image"), max(_display_width(t.base_image) for t in tasks)) + 2
    col_parser = max(_display_width("Parser"), max(_display_width(t.judge.parser) for t in tasks)) + 2

    print(f"{_pad('ID', col_id)} {_pad('Name', col_name)} {_pad('Base Image', col_base)} {_pad('Parser', col_parser)}")
    print("-" * (col_id + col_name + col_base + col_parser + 3))
    for t in tasks:
        print(f"{_pad(t.task_id, col_id)} {_pad(t.name, col_name)} {_pad(t.base_image, col_base)} {_pad(t.judge.parser, col_parser)}")



def cmd_fetch_tasks(args):
    """Download benchmark task definitions from HuggingFace Hub."""
    from huggingface_hub import snapshot_download
    from sforge.harness.constants import BENCHMARK_REGISTRY, DEFAULT_BENCHMARK

    benchmark = args.benchmark or DEFAULT_BENCHMARK
    repo_id = args.repo or BENCHMARK_REGISTRY.get(benchmark)
    if not repo_id:
        available = ", ".join(sorted(BENCHMARK_REGISTRY))
        print(
            f"Error: unknown benchmark '{benchmark}'. "
            f"Available: {available}\n"
            f"Or specify --repo <org/repo> directly.",
            file=sys.stderr,
        )
        sys.exit(1)

    tasks_dir = Path(args.tasks_dir).resolve() if args.tasks_dir else Path("tasks").resolve()
    revision = args.revision or None

    print(f"Fetching tasks from HuggingFace Hub")
    print(f"  Repo:      {repo_id}")
    if revision:
        print(f"  Revision:  {revision}")
    print(f"  Target:    {tasks_dir}")
    print()

    snapshot_download(
        repo_id=repo_id,
        repo_type="dataset",
        local_dir=str(tasks_dir),
        revision=revision,
    )

    n_tasks = sum(1 for p in tasks_dir.glob("*.json"))
    print(f"\nDone. {n_tasks} task file(s) in {tasks_dir}")


# --- Main parser ---


def main():
    parser = argparse.ArgumentParser(
        prog="sforge",
        description="SForge: Evaluation harness for coding agents",
    )

    # Global flags
    parser.add_argument("--log-dir", dest="log_dir", default=None)
    parser.add_argument("--tasks-dir", dest="tasks_dir", default=None)
    parser.add_argument("--silent", action="store_true", default=False,
                        help="Suppress detailed log output (auto-enabled for multi-task runs)")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # build
    p_build = subparsers.add_parser("build", help="Build work + judge images")
    p_build_group = p_build.add_mutually_exclusive_group(required=True)
    p_build_group.add_argument("--task", nargs="+",
                               help="One or more task IDs (e.g. --task minitorch gitlet)")
    p_build_group.add_argument("--all", action="store_true", default=False,
                               help="Build images for all tasks")
    p_build.add_argument("--force-rebuild", action="store_true", default=False,
                         help="Force rebuild work + judge images (skip base)")
    p_build.add_argument("--force-rebuild-with-base", action="store_true", default=False,
                         help="Force rebuild ALL images including base")
    p_build.add_argument("--kits-dir", default=None,
                         help="Build work/judge from exported build kits at "
                              "<kits-dir>/<task_id>/{work,judge}/ instead of setup_cmds "
                              "(base is built from BENCHMARK.yaml as usual)")
    p_build.add_argument("--verify", action="store_true", default=False,
                         help="With --kits-dir: verify built images file-by-file "
                              "against the kits' MANIFEST.sha256")
    p_build.set_defaults(func=cmd_build)

    # pull
    p_pull = subparsers.add_parser("pull", help="Pull pre-built images from remote registry")
    p_pull_group = p_pull.add_mutually_exclusive_group(required=True)
    p_pull_group.add_argument("--task", nargs="+",
                              help="One or more task IDs")
    p_pull_group.add_argument("--all", action="store_true", default=False,
                              help="Pull images for all tasks")
    p_pull.add_argument("--registry", dest="registry", default=None,
                        help="Remote container registry (overrides SFORGE_REGISTRY)")
    p_pull.set_defaults(func=cmd_pull)

    # push
    p_push = subparsers.add_parser("push", help="Push built images to remote registry")
    p_push_group = p_push.add_mutually_exclusive_group(required=True)
    p_push_group.add_argument("--task", nargs="+",
                              help="One or more task IDs")
    p_push_group.add_argument("--all", action="store_true", default=False,
                              help="Push images for all tasks")
    p_push.add_argument("--registry", dest="registry", default=None,
                        help="Remote container registry (overrides SFORGE_REGISTRY)")
    p_push.set_defaults(func=cmd_push)

    # run
    p_run = subparsers.add_parser("run", help="Run an agent on one or more tasks")
    p_run.add_argument("--backend", choices=["docker", "k8s"], default=None,
                       help="Container backend (default from SFORGE_BACKEND or 'docker')")
    p_run.add_argument("--task", default=None, nargs="+",
                       help="One or more task IDs (e.g. --task ahc056 ahc057). "
                            "Multiple tasks are run fully in parallel.")
    p_run.add_argument("--experiment", default=None,
                       help="Path to experiment YAML config file (model config + per-task overrides)")
    p_run.add_argument("--agent", default=None, help="Agent name (claude-code, aider, codex)")
    p_run.add_argument("--model", default=None, help="Model override")
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
    p_run.add_argument("--judge-url", default="http://host.docker.internal:8080", help="Judge server URL")
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
    p_eval = subparsers.add_parser("eval", help="Evaluate an archive")
    p_eval.add_argument("--backend", choices=["docker", "k8s"], default=None,
                        help="Container backend (default from SFORGE_BACKEND or 'docker')")
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
    p_serve = subparsers.add_parser("serve", help="Start judge HTTP server")
    p_serve.add_argument("--host", default="0.0.0.0")
    p_serve.add_argument("--port", type=int, default=8080)
    p_serve.set_defaults(func=cmd_serve)

    # proxy
    p_proxy = subparsers.add_parser(
        "proxy", help="Start local API reverse proxy (for --disable-internet)"
    )
    p_proxy.add_argument(
        "--target", required=True,
        help="Upstream API URL to forward to (e.g. https://api.anthropic.com)",
    )
    p_proxy.add_argument("--host", default="0.0.0.0")
    p_proxy.add_argument("--port", type=int, default=9090)
    p_proxy.set_defaults(func=cmd_proxy)

    # visualizer
    p_viz = subparsers.add_parser("visualizer", help="Start run-results visualizer web UI")
    p_viz.add_argument("--runs-dir", default="logs/runs", help="Directory of run folders")
    p_viz.add_argument("--tasks-dir", dest="tasks_dir", default=None, help="Directory of task JSONs (for score_direction). Defaults to the harness tasks/ dir.")
    p_viz.add_argument("--host", default="127.0.0.1")
    p_viz.add_argument("--port", type=int, default=8000)
    p_viz.set_defaults(func=cmd_visualizer)

    # list
    p_list = subparsers.add_parser("list", help="List available tasks")
    p_list.set_defaults(func=cmd_list)

    # fetch-tasks
    p_fetch = subparsers.add_parser(
        "fetch-tasks",
        help="Download benchmark task definitions from HuggingFace Hub",
    )
    p_fetch.add_argument(
        "benchmark", nargs="?", default=None,
        help="Benchmark name (default: edgebench). Use --repo for unlisted repos.",
    )
    p_fetch.add_argument(
        "--repo", default=None,
        help="HuggingFace repo ID (e.g. ByteDance-Seed/EdgeBench). "
             "Overrides the benchmark name lookup.",
    )
    p_fetch.add_argument(
        "--revision", default=None,
        help="Git revision (branch, tag, or commit hash) to download.",
    )
    p_fetch.set_defaults(func=cmd_fetch_tasks)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
