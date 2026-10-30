import { createRequire } from "module";
import { fileURLToPath } from "url";
export let passed = 0;
export let failed = 0;
const arcRoot = process.env.ARC_TEST_ROOT ?? fileURLToPath(new URL("../..", import.meta.url));
const requireArc = createRequire(import.meta.url);
function pass() { passed++; }
function fail(name: string, e: any) { failed++; if (failed <= 4) console.error(`  FAIL: ${name} — ${e?.message ?? e}`); }
function assert(cond: boolean, msg: string) { if (!cond) throw new Error(msg); }
function deepEqual(a: any, b: any): boolean { return JSON.stringify(a) === JSON.stringify(b); }

// Public smoke tests: stdlib basics. Case count: 8.
const cases = [
  ["SMOKE-STD-001", "map([1,2,3], x => x * 2)", [2,4,6]],
  ["SMOKE-STD-002", "filter([1,2,3], x => x > 1)", [2,3]],
  ["SMOKE-STD-003", "reduce([1,2,3], (a,b) => a + b, 0)", 6],
  ["SMOKE-STD-004", "join([\"a\",\"b\"], \",\")", "a,b"],
  ["SMOKE-STD-005", "upper(\"hi\")", "HI"],
  ["SMOKE-STD-006", "range(0,3)", [0,1,2]],
  ["SMOKE-STD-007", "keys({a:1})", ["a"]],
  ["SMOKE-STD-008", "contains([1,2], 2)", true],
] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);
for (const [id, src, expected] of cases) { try { const actual = interpretWithEnv(parse(lex(src)), createEnv()); assert(deepEqual(actual, expected), `${id} expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`); pass(); } catch (e: any) { fail(String(id), e); } }
console.log(`  ${passed} passed, ${failed} failed`);
