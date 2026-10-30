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

// Public smoke tests: interpreter basics. Case count: 8.
const cases = [
  ["SMOKE-INT-001", "1 + 2 * 3", 7],
  ["SMOKE-INT-002", "let x = 4; x + 1", 5],
  ["SMOKE-INT-003", "fn add(a,b){ a + b }; add(2,3)", 5],
  ["SMOKE-INT-004", "if true { 10 } else { 0 }", 10],
  ["SMOKE-INT-005", "let mut x = 0; x = x + 2; x", 2],
  ["SMOKE-INT-006", "len([1,2,3])", 3],
  ["SMOKE-INT-007", "\"ha\" * 3", "hahaha"],
  ["SMOKE-INT-008", "sum([1,2,3])", 6],
] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);
for (const [id, src, expected] of cases) { try { const actual = interpretWithEnv(parse(lex(src)), createEnv()); assert(deepEqual(actual, expected), `${id} expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`); pass(); } catch (e: any) { fail(String(id), e); } }
console.log(`  ${passed} passed, ${failed} failed`);
