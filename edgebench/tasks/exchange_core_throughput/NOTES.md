# exchange_core_throughput

The agent tunes exchange-core (an LMAX Disruptor matching engine, Java 8 sources, Maven) for
throughput. The judge re-adds the upstream tests and runs
`mvn -B test -Dtest=PerfThroughput#testThroughputPeak`. Raw score = `int(round(Average MT/s * 1000))`
(maximize). The rescale is the v1 one (`log_max`, baseline 2090.6, expert 6000).

## Source

- exchange-core: the public GitHub repository `foreverpiano/exchange-core` at
  `2f8548749839e9095c8dc597e4b61521d259fa5d` (2022-05-14, an upstream exchange-core commit).
  `environment/exchange-core/` is that tree without `src/test`; `judge/upstream-src-test/` is its
  `src/test`. v1's edits (lombok-maven-plugin 1.18.12.0 -> 1.18.20.0; removing the `ITOrderBook*`
  tests and three tuning lines of `PerfThroughput.java`) are replayed in the Dockerfiles.
- `judge/eval_exchange_core.py`: byte-identical to v1's eval script. `judge/run.sh` and
  `judge/write_result.py` are new and write `result.json` with v1's scoring.
- Maven dependencies: `environment/m2/central.tsv` lists every artifact of v1's work-image Maven
  repository with size and sha256; the build downloads them from Maven Central and fails on any
  mismatch. The resulting `/root/.m2` is byte-identical to v1's. `judge/m2-extra/` adds the
  artifacts the v1 judge downloaded at run time (surefire's JUnit Platform provider, and the
  plugins historical submissions pinned in their `pom.xml`), since the judge is now offline.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/java` (Java 17, Maven 3.9).

## Deviations from v1

1. **Root only** (SCHEMA rule 3), which changes what the agent can do: in v1 the agent user could
   not read `/root/.m2` and had no network, so `mvn compile` failed offline in the work image. Now
   `mvn -o compile` works.
2. **The judge is offline.** Maven resolves only from the pinned repository. All 48 distinct
   `pom.xml` variants among historical submissions build on the new judge, but a `pom.xml` that
   needs an artifact no historical submission used now fails to build (v1 downloaded it).
3. The eval script moved from `/tmp` to `/judge/`.
4. `valid` = a `TOTAL_SCORE` was printed (v1 recorded an unrankable score when it was missing,
   which only happens if the eval script crashes). The test pass flag is informational.
5. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge, with network as in v1) and new judge (offline) on the same submissions,
same shared host, interleaved, four runs per side. Raw score: median, with the range of runs.

| Submission | Old | New |
|---|---|---|
| empty (unmodified repository) | 6838 (6728–6949) | 6764 (6540–6988) |
| historical 1 (runtime error) | 0 | 0 |
| historical 2 | 2875 (2852–2887) | 2842 (2488–2866) |
| historical 3 | 2856 (2303–3224) | 2890 (2536–3208) |
| historical 4 | 2424 (2038–2447) | 2419 (2269–2447) |
| historical 5 | 4592 (4547–4728) | 4624 (4569–4676) |
| historical 6 | 4597 (4291–4678) | 4621 (4261–4693) |

Medians differ by at most 1.2%, within the old judge's own spread; pass/fail outcomes are
identical. The historical v1 scores come from another host and match neither side (Known issue 1).

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The score depends heavily on the host.** On a 192-thread host the unmodified repository
   scores about 6800 (100/100), above every historical submission measured there, while the top
   historical submission (7061 in v1) gets about 4600. The rescale baseline and the instruction's
   reference numbers come from other hosts, and the judge sets no CPU limit while the benchmark's
   threads busy-spin. Rankings are not portable across hosts.
2. **The submission can inject a score.** The eval takes the first throughput line anywhere in
   Maven's output, which includes the output of the submitted code, and on the failure path a
   printed `TOTAL_SCORE` also wins. The submitted `pom.xml` can also redirect the test sources.
   Related to the cross-task issue in `tasks/SCHEMA.md`.
3. **Functional assertions are not enforced.** The instruction says `mvn test` must pass, but the
   score is the parsed throughput even when Maven fails.
4. **Misleading tuning hint.** The instruction suggests `.mvn/jvm.config` for JVM options, but
   that configures Maven's JVM, not the forked test JVM that runs the benchmark.
5. **The agent cannot run the benchmark offline.** The work image lacks the JUnit Platform
   provider (as in v1), so recreating and running the test fails; only compiling works.
