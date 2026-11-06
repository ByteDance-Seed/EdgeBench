# EdgeBench

The 51 public [EdgeBench](../README.md) tasks, as a benchmark for [SForge](https://bytedance-seed.github.io/EdgeBench/):

```
benchmark.toml       name, image registry (docker.io/seededge), blob URL
tasks/<task_id>/     one directory per task: prompt, environment, grader, NOTES.md
bases/<name>/        shared toolchain images
```

Run a task from the repository root, where SForge uses this directory by default:

```bash
sforge pull --task ad_placement_optimization
sforge run --task ad_placement_optimization --agent claude-code
```

Found a problem or want to improve a task? Open an issue or a pull request against its
directory. Tasks follow SForge's [Task Format](https://bytedance-seed.github.io/EdgeBench/en/tasks/task-format)
and EdgeBench's rules in [`tasks/SCHEMA.md`](tasks/SCHEMA.md).

Licensed under [CC BY 4.0](LICENSE); third-party files inside a task keep their own licenses.
