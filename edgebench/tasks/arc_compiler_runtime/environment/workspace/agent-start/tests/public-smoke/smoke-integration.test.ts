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

// Public smoke tests: small integration examples. Case count: 8.
const cases = [
  ["SMOKE-X-001", "let xs = [1,2,3]; sum(map(xs, x => x + 1))", 9],
  ["SMOKE-X-002", "fn inc(x){ x + 1 }; map([1,2], inc)[0]", 2],
  ["SMOKE-X-003", "let name = \"Arc\"; \"hi {name}\"", "hi Arc"],
  ["SMOKE-X-004", "let m = {a:1,b:2}; len(keys(m))", 2],
  ["SMOKE-X-005", "for x in [1] { print(x) }; 1", 1],
  ["SMOKE-X-006", "match 2 { 1 => \"one\", _ => \"other\" }", "other"],
  ["SMOKE-X-007", "let mut x = 1; x = x + 1; x", 2],
  ["SMOKE-X-008", "range(0, 3) |> sum()", 3],
] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);
for (const [id, src, expected] of cases) { try { const actual = interpretWithEnv(parse(lex(src)), createEnv()); assert(deepEqual(actual, expected), `${id} expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`); pass(); } catch (e: any) { fail(String(id), e); } }
console.log(`  ${passed} passed, ${failed} failed`);
