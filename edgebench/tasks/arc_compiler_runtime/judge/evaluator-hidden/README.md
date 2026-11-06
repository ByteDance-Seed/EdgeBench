# Arc hidden evaluator

This evaluator-only package contains hidden SPEC_CONFIRMED tests for the Arc language benchmark. It must not be included in the agent-visible starter package.

## Usage

Score either a submitted public package root or its `agent-start/` directory:

```bash
bash evaluator-hidden/score_hidden.sh /path/to/submission-root
bash evaluator-hidden/score_hidden.sh /path/to/submission-root/agent-start
SUBMISSION_ROOT=/path/to/submission-root/agent-start bash evaluator-hidden/score_hidden.sh
```

The script auto-detects whether the input is the package root or `agent-start/`. It copies the submitted `agent-start/` into a temporary workspace, copies hidden tests into that temporary copy, and runs there so the original submission is not modified.

The evaluator is offline and uses the submission's vendored Node dependencies. It does not require network, GPU, mouse operation, video, or human interaction.

## Infra-failure policy

A hidden suite must report a real positive denominator. The runner accepts either exported numeric `passed`/`failed` counters or a stdout summary matching `X passed, Y failed`. If a suite reports `0/0`, lacks both counters and a parseable stdout summary, cannot be collected, or exits before producing a valid result, the evaluator returns:

```text
SCORE_STATUS=INFRA_FAIL
```

Candidate implementation import/compile failures under the submitted `compiler/` tree are scored as real test failures for that suite (`0/N`) rather than hidden evaluator infrastructure failures. Missing submission paths, missing vendored dependencies, missing runner, hidden test path errors, or hidden test collection errors are infrastructure failures.

## Scoring

- Hidden raw total: 448
- Hidden weighted total: 2970
- Formula: `SCORE = 100 * WEIGHTED_PASSED / WEIGHTED_TOTAL`
- Difficulty weights are file-level and capped at 8 in this hidden package.

The hidden tests focus on parser boundary behavior, adversarial type-system checks, interpreter/codegen consistency, stdlib composition, toolchain edges, and cross-module integration. They are based on the public CHEATSHEET/problem/TASK language contract, but the concrete hidden cases should not be exposed to agents.
