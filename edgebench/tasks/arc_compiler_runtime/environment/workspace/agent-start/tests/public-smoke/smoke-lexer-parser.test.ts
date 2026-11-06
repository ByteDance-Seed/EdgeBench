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

// Public smoke tests: lexer/parser basics. Case count: 8.
const cases = [
  ["SMOKE-PARSE-001", "let x = 1", ["x"]],
  ["SMOKE-PARSE-002", "1 + 2 * 3", ["+"]],
  ["SMOKE-PARSE-003", "fn add(a,b){ a + b }", ["add"]],
  ["SMOKE-PARSE-004", "if true { 1 } else { 0 }", ["If"]],
  ["SMOKE-PARSE-005", "[1,2,3]", ["1"]],
  ["SMOKE-PARSE-006", "{a:1,b:2}", ["a"]],
  ["SMOKE-PARSE-007", "for x in [1,2] { print(x) }", ["for", "x"]],
  ["SMOKE-PARSE-008", "match n { 1 => \"one\", _ => \"many\" }", ["match", "many"]],
] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
for (const [id, src, needles] of cases) { try { const ast = parse(lex(src)); const encoded = JSON.stringify(ast); assert(Array.isArray(ast.stmts), `${id} program stmts`); for (const n of needles) assert(encoded.toLowerCase().includes(String(n).toLowerCase()), `${id} missing ${n}`); pass(); } catch (e: any) { fail(String(id), e); } }
console.log(`  ${passed} passed, ${failed} failed`);
