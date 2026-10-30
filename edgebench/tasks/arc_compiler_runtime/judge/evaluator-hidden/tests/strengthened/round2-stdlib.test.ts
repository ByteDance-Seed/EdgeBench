// Stage: Stdlib
// Case count: 8
// Provenance: SPEC_CONFIRMED from CHEATSHEET built-in string/list/map/type_of functions.
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

console.log("Round2 Strengthened Stdlib Tests:");

test("trim upper lower compose deterministically", () => {
  assert(run('lower(upper(trim("  Arc  ")))') === "arc", "trim/upper/lower composition");
});

test("split and join roundtrip simple separator", () => {
  assert(run('join(split("a,b,c", ","), "|")') === "a|b|c", "split join composition");
});

test("slice returns expected substring boundary", () => {
  assert(run('slice("hello", 1, 4)') === "ell", "slice boundary");
});

test("list any and all with predicates", () => {
  assert(run("any([1,2,3], x => x > 2) and all([1,2,3], x => x > 0)") === true, "any/all predicate behavior");
});

test("take and drop partition a list", () => {
  const r = run("concat(take([1,2,3,4], 2), drop([1,2,3,4], 2))");
  assert(Array.isArray(r) && r.join(",") === "1,2,3,4", "take/drop partition");
});

test("flat removes one nesting layer", () => {
  const r = run("flat([[1], [2, 3]])");
  assert(Array.isArray(r) && r.join(",") === "1,2,3", "flat one layer");
});

test("map keys and values expose entries", () => {
  assert(run("len(keys({a:1,b:2})) == 2 and len(values({a:1,b:2})) == 2") === true, "keys/values counts");
});

test("type_of distinguishes list and map", () => {
  assert(run('type_of([]) == "list" and type_of({a:1}) == "map"') === true, "type_of list and map");
});

console.log(`  ${passed} passed, ${failed} failed`);
