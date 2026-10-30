# Jagua Nesting Optimizer

## Background

This task is based on the `lbf` crate from `jagua-rs`. `jagua-rs` is a Rust research project for collision detection in 2D irregular cutting/packing/nesting problems, and `lbf` is the left-bottom-fill reference optimizer provided with the repository. The reference implementation demonstrates how to use the collision detection engine, but solution quality is sensitive to item ordering, sampling strategy, and random seeds, leaving significant room for improvement toward a stable, production-quality optimizer.

## Your Goal

You need to improve the `lbf` optimizer so that it produces shorter strip widths than the original LBF reference on hidden strip packing benchmark instances. You may modify code in `lbf/src/` and, where necessary, `jagua-rs/src/`, but must preserve the CLI interface:

```bash
cargo run --release --bin lbf -- -i <instance.json> -p spp -c <config.json> -s <solution_dir> -l warn
```

## Scoring

The Judge will run both the original reference and your candidate implementation on hidden instances, and independently verify the geometric feasibility of each output solution. Each case's score is based on the relative strip width improvement over the reference, but scoring is nonlinear: very small improvements yield little or no score, while larger and consistent improvements score significantly. Running time also affects scoring; simply adding many restarts, ordering enumerations, or random sampling attempts that approach the timeout will be heavily penalized. No valid improvement, illegal output, missing items, out-of-bounds placement, overlaps, timeout, or program crashes all result in a score of 0. The total score is a weighted continuous score across all cases, with a maximum of 100.

## Constraints

- Do not change the CLI argument semantics or the basic structure of the solution JSON.
- Do not output fabricated solutions; the Judge will reconstruct polygons and perform independent geometric verification.
- Do not rely on network, GPU, external services, or non-repository dependencies.
- You may use multi-start, reordering, local search, adaptive configuration, sampling strategy modifications, caching, and deterministic scheduling, but must control total running time.
- Prioritize robustness and effectiveness; high scores require simultaneously achieving solution quality, cross-instance generalization, and stable performance.

## Directory Hints

- `lbf/src/opt/search.rs`: Current placement search and item ordering.
- `lbf/src/opt/lbf_spp.rs`: SPP solver main loop.
- `lbf/src/config.rs`: LBF configuration.
- `assets/`: Public examples, available for development; hidden evaluation instances will not appear in the Work environment's `assets/` directory.
