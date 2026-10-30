// Stage: Interpreter
// Case count: 8
// Provenance: SPEC_CONFIRMED from CHEATSHEET functions, recursion, closures, loops, short-circuit logic, pipeline, interpolation, and runtime errors.
// Included in official scoring: YES. Does not depend on evaluator-only artifacts or network.
import { createRequire } from "module";

export let passed = 0;
export let failed = 0;

const arcRoot = process.env.ARC_TEST_ROOT ?? new URL("../..", import.meta.url).pathname;
const requireArc = createRequire(import.meta.url);
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);

function run(src: string): any { return interpretWithEnv(parse(lex(src)), createEnv()); }
function assert(cond: boolean, msg: string) { if (cond) passed++; else { failed++; console.error(`  FAIL: ${msg}`); } }
function test(name: string, fn: () => void) { try { fn(); } catch (e: any) { failed++; console.error(`  FAIL: ${name} — ${e?.message ?? e}`); } }
function throws(fn: () => void): boolean { try { fn(); return false; } catch { return true; } }

console.log("Round2 Strengthened Interpreter Tests:");

test("recursive factorial with nested branch", () => {
  assert(run("fn fact(n) => if n <= 1 { 1 } el { n * fact(n - 1) }; fact(6)") === 720, "recursive factorial result");
});

test("closure captures outer parameter", () => {
  assert(run("fn make_adder(a) { fn add_b(b) => a + b; add_b }; let add5 = make_adder(5); add5(7)") === 12, "closure capture works");
});

test("false and short-circuits dangerous expression", () => {
  assert(run("false and (1 / 0 > 0)") === false, "and short-circuits left false");
});

test("do until executes until condition becomes true", () => {
  assert(run("let mut x = 0; do { x = x + 1 } until x >= 3; x") === 3, "do-until result");
});

test("rest parameter reduces values", () => {
  assert(run("fn total(...xs) { reduce(xs, (a, b) => a + b, 0) }; total(1, 2, 3, 4)") === 10, "rest parameter reduction");
});

test("pipeline combines filter map and sum", () => {
  assert(run("[1,2,3,4,5] |> filter(x => x % 2 == 1) |> map(x => x * 3) |> sum") === 27, "pipeline result");
});

test("string interpolation evaluates embedded expression", () => {
  assert(run("let items = [10, 20]; \"first: {items[0] + 1}\"") === "first: 11", "computed interpolation");
});

test("division by zero throws runtime error", () => {
  assert(throws(() => run("1 / 0")), "division by zero is a runtime failure");
});

console.log(`  ${passed} passed, ${failed} failed`);
