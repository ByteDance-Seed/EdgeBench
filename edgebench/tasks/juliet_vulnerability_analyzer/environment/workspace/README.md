# Juliet Static Vulnerability Analyzer v3

Build a facts-level C/C++ static vulnerability analyzer. The benchmark is anchored to the pinned NIST SARD Juliet C/C++ 1.3 Test Suite #112 corpus, but solvers receive only pre-generated facts, not the raw corpus.

## Task

Implement `agent-start/analyzer.py`. It receives:

```bash
python3 agent-start/analyzer.py --input data/public/facts.jsonl --output agent-start/out/findings.json
```

The output is SARIF-like JSON:

```json
{"findings": [{"case_id": "...", "cwe": "CWE-476", "source_stmt": 12, "sink_stmt": 42, "trace": [12, 18, 42], "confidence": 0.8}]}
```

A finding matches by `(case_id, cwe, sink_stmt)`, but high score also requires a valid bounded `trace`. `source_stmt` must identify the source/allocation/release witness for the claimed flow. `trace` must start at `source_stmt`, end at `sink_stmt`, contain only statement ids from the case, avoid repeated/all-file broad supersets, and include the important propagation/guard/lifetime witness statements when relevant.

## Public facts schema

Each JSONL row is one transformed Juliet-derived case:

- `case_id`: scrubbed stable case identifier.
- `functions`: scrubbed functions with `id`, `start_stmt`, `end_stmt`.
- `stmts`: lower-level statement facts with `stmt_id`, `function`, `kind`, `token_shape`, normalized `tokens`, syntactic `ops`, optional `call` facts, and optional `type_hints`.
- `cfg_edges`: approximate fallthrough/control edges between statement ids.
- `values`: scrubbed value identifiers.
- `calls`: low-level call facts with scrubbed function id, callee name where it is a public C/library API, and argument-count hint.

Facts do not contain per-statement `candidate_cwes`, `sink_candidate`, `source_classes`, `sanitizer_classes`, or per-case vulnerability-family shortcuts. Original Juliet paths, CWE directories, good/bad names, function names, comments, and transform mappings are not solver-facing.

## Required semantics

Analyze source-to-sink and lifetime flows for: CWE-121, CWE-122, CWE-190, CWE-476, CWE-416, CWE-78.

- Infer external inputs, boundary integer values, null values, arrays/buffers, allocations, frees, command execution, buffer copy, integer operations, pointer dereference, and use sites from call/token/operator facts.
- Recognize guards and sanitizers from conditions, comparisons, null checks, bounds checks, and relevant API/token evidence.
- Interprocedural/call summaries, path/range reasoning, alias/lifetime reasoning, and false-positive control are needed for high score.
- Do not report every dangerous-looking API/operator: public and hidden include many safe/negative sinks.
- Do not use broad traces such as all statements before the sink; sink-only or broad traces are scored as invalid trace evidence.

## Commands

```bash
bash score.sh
bash verify_task.sh
docker build -t juliet-static-analyzer-v3 .
docker run --rm --network=none juliet-static-analyzer-v3
```

## Prohibited

Do not call CodeQL, Joern, Infer, Semgrep, clang static analyzer, cppcheck, network tools, or hidden expected outputs. Do not hardcode Juliet original paths, filenames, function names, case IDs, or label mappings.

## Dataset summary

Public labels: 192. Hidden labels (evaluator-only): 723. Corpus SHA256: `ada9d7e1c323d283446df3f55bdee0d00bda1fed786785fe98764d58688f38eb`.
