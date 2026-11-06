# Problem 1 · Full Specification (task-author internal document)

> This document is intended for **reviewers** and **evaluation-service operators**, and covers every detail that must not be exposed in the README handed to the Agent.

## 1. Task Overview

- **Task name**: Extreme optimization of integer compression codecs
- **Task category**: Code optimization
- **Evaluation form**: Remote black-box evaluation (submit a `.tar.gz`, receive a numeric score)
- **Target model**: Autoregressive LLMs (Claude/GPT-4 class or newer) as the Agent
- **Estimated effort**: 12+ hours of continuous AI work; a human expert working full-time can still keep improving after 3+ days

## 2. ABI Contract (immutable)

See `workspace/include/intcompress.h`. Three functions with C linkage; parameter/return signatures are frozen. Any modification to this header makes the evaluation return `compile_error` directly (server.py uses its own copy as the `-I` path).

## 3. Dataset Generation Details

Fully defined by `workspace/tools/gen_data.py`. For reviewers' convenience, the **mathematical description** consistent with the code is given here:

| # | name | Formula (Python / numpy) | Remote N | Properties |
|---|---|---|---|---|
| 1 | docids  | `cumsum(Pareto(1.2)+1)` scaled to `[0, 2^31)` | 100M | strictly ascending, long-tail gaps |
| 2 | ts_sec  | `floor(1577836800 + cumsum(Exp(1/1000)))` | 50M | ascending, duplicate seconds |
| 3 | ts_ns   | `(base_ns + cumsum(Exp(1000))) & 0xFFFFFFFF` | 50M | ascending but wrapping, constant high bits |
| 4 | temp    | `clip(Normal(25, 3) * 100, 0, 10000)` | 50M | centered small integers |
| 5 | grid    | `Morton(U16 lat, U16 lon) + jitter(±16)` | 50M | medium entropy, locally correlated |
| 6 | zipf    | `zipf(s=1.1)[< 500K]` | 50M | Zipfian long tail |
| 7 | rand    | `uniform(0, 2^32)` | 50M | uniformly random (worst case) |
| 8 | sparse  | `sorted( 50% hot[100] ∪ 50% U32 )` | 50M | hotspot + sparse mix |

Seeds are fixed at 1001..1008. The local samples handed to the Agent use roughly 1/40 of the above N, but with **identical seeds** — this is a deliberate anti-cheat design: the data is not a secret and is publicly reproducible, so the Agent cannot derive any "hidden trick" of the remote data by analyzing the local samples.

## 4. Scoring Math

### 4.1 Combined score

Per dataset:
```
bpi_i        = encoded_bytes_i * 8 / n_i
comp_i       = min( baseline_bpi_i / bpi_i,       8.0 )
speed_i      = min( gbps_i      / baseline_gbps_i, 40.0 )
S_i          = comp_i * speed_i        (0 if roundtrip_ok=false)
Score        = Σ w_i S_i / Σ w_i
```

Weights `w = [2.0, 1.5, 1.5, 1.0, 1.0, 1.0, 1.0, 1.0]`.

### 4.2 Rationale for the caps

- `comp_i ≤ 8`: the information-theoretic maximum compression ratio for uint32 is about 8× (constant columns can reach 32× but that is meaningless in practice); the cap prevents score farming on degenerate datasets (e.g. all zeros).
- `speed_i ≤ 40`: the single-core AVX2 decode limit is about 30-35 GB/s; the cap allows some headroom but rejects obvious exploitation of evaluation loopholes.

### 4.3 Final score

`final_score = max(total_score over all submissions)`.

## 5. Measurement Protocol

1. The service receives the `.tar.gz` from the Agent (≤ 32 MiB)
2. Compiles with `make -j4` inside the `intcompress-runner` container (5-minute cap)
3. Binary symbol allowlist check (see the scoring-standard document, rules R1/R2)
4. For the 8 datasets in fixed order:
   - **Process A**: `runner_encode <input.u32> <lib.so> <out.enc> <out.meta>`
   - **Process B**: `runner_decode <out.enc> <lib.so> <input.u32> <result.json>`
   - Process B compares the decoded output against the original `input.u32` with a byte-wise memcmp
   - decode runs 5 times, shortest time taken (best stability, resists noisy neighbors)
5. Aggregate, write `{submission_id}.json`
6. Clean up the working directory

**Key anti-cheat points**:
- Process A and process B run in different containers; encode and decode share no memory, so nothing can be "remembered" about the original input across calls.
- Dataset paths carry a random suffix (`/srv/intcompress/data/docids-<uuid>.u32`); submissions cannot read the data ahead of time via hard-coded paths.
- The encode process mounts no data file other than `input.u32`; the decode process mounts only the encode output plus the original file (the latter is used solely for the verification compare and is never shown to the lib) — in fact `runner_decode` passes only the encoded buffer to the lib.

## 6. Reference Implementations (internal baselines)

`internal/baseline/reference_solutions/` (**not handed out**) contains three reference implementations for reviewer comparison:

| Implementation | Total score | LOC | Notes |
|---|---|---|---|
| `00_varint/`   | 1.0 | ~80 | identical to the handed-out baseline |
| `10_delta_bp/` | ~10.8 | ~420 | Delta + fixed-width bit-packing (no SIMD) |
| `20_bp128/`    | ~18.5 | ~1350 | Delta + SIMD-BP128 (AVX2) |
| `30_fastpfor/` | ~26.4 | ~2200 | + FastPFor exceptions + Elias-Fano (ascending) |

Used for:
- Verifying that the evaluation service scores monotonically (stronger algorithms score higher)
- Regression testing (run after every server.py change)
- Providing typical curve data for the "R11 cross-submission improvement monotonicity" rule

## 7. Pre-launch Checklist

- [ ] Both Docker images build successfully (`intcompress-server`, `intcompress-runner`)
- [ ] Baseline yields `total_score ≈ 1.0`
- [ ] `10_delta_bp` reference yields `total_score` ∈ [9.5, 12.0]
- [ ] `20_bp128` reference yields `total_score` ∈ [17.0, 20.0]
- [ ] `30_fastpfor` reference yields `total_score` ∈ [24.0, 29.0]
- [ ] Deliberately submit a malicious lib containing `system("echo hi")` → rejected by R2
- [ ] Deliberately submit a lib failing roundtrip → that dataset `S_i = 0`, others scored normally
- [ ] Deliberately submit a lib whose encoding inflates > 16n → encode returns SIZE_MAX, `S_i = 0`
- [ ] Deliberately have encode call `fork()` → rejected by R2
- [ ] API `POST /submit` returns 429 after 100 submissions
- [ ] `leaderboard` correctly returns the max total_score rather than the mean or the latest

## 8. Contamination-control Addendum

- Descriptions of the Lucene / FastPFor / SIMD-BP128 papers appear frequently in LLM training data, but the **concrete bit-packing kernel implementations** are hard to recall correctly without running tests. The evaluation's extensive per-dataset feedback forces contestants to fix bugs and tune parameters; reciting memorized code almost never passes on the first try.
- The optimal strategy differs across the 8 datasets; no single "universal algorithm" can achieve full marks. A memorized single algorithm only reaches the mid range (about 3-8M).
- Anti-cheat hardening: `runner_decode` randomly picks one of the decode runs, MD5-checks its output, and compares it against the MD5 of the original input; if a contestant returns correct data only on the first decode and random data afterwards, the MD5 exposes it.

## 9. Operations Contacts

- Evaluation machines: `ice-lake-4vcpu-01` ~ `ice-lake-4vcpu-08` (8 machines, load-balanced)
- Alerting: `grep -c '"status": "error"' /var/lib/intcompress/results/*.json` exceeding 30%/hour triggers PagerDuty
- Log rotation: `RESULT_DIR` archived to object storage every 7 days; `WORK_ROOT` kept for 1 day
