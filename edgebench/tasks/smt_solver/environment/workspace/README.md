# SE-Bench SMT Solver

Implement an SMT solver from scratch for a restricted SMT-LIB 2 subset.

Your submission root must contain:

```text
build.sh
solve
src/
```

The evaluator runs `./build.sh`, then calls:

```bash
./solve path/to/input.smt2
```

For satisfiable inputs, print `sat` followed by a JSON model witness. The evaluator validates the model against the exact SMT-LIB input passed to your solver:

```text
sat
{"values":{"x":"3","r":"(/ 7 2)","b":"true","a":"@a","(f a)":"@fa"}}
```

For unsatisfiable or unsupported inputs, print exactly one non-empty line:

```text
unsat
```

or:

```text
unknown
```

`unknown` earns 0. `unsat` without a proof certificate is accepted as a formatted status but earns only capped partial credit on true UNSAT cases. A high score requires valid SAT witnesses and semantic solving, not status guessing.

The public `benchmarks/` directory is a compact smoke/development set. It is not representative of the hidden distribution and must not be used to infer `sat`/`unsat` priors, file-size rules, family patterns, hashes, or other benchmark fingerprints.

Run local scoring with:

```bash
python3 scripts/evaluate.py \
  --solver ./solve \
  --benchmarks benchmarks \
  --timeout 60 \
  --parallel 4 \
  --output public_score.json
```

Read `smtlib_spec.md` for the supported syntax, output schema, scoring details, and restrictions.
