import { createRequire } from "module";
import { fileURLToPath } from "url";

export let passed = 0;
export let failed = 0;

const fallbackRoot = fileURLToPath(new URL("../../..", import.meta.url));
const arcRoot = process.env.ARC_TEST_ROOT ?? fallbackRoot;
const requireArc = createRequire(import.meta.url);

function pass() { passed++; }
function fail(name: string, e: any) { failed++; if (failed <= 8) console.error(`  FAIL: ${name} — ${e?.message ?? e}`); }
function deepEqual(a: any, b: any): boolean { return JSON.stringify(a) === JSON.stringify(b); }
function assert(cond: boolean, msg: string) { if (!cond) throw new Error(msg); }

// Hidden evaluator file: cross-module integration
// Case count: 16
// Provenance: SPEC_CONFIRMED from CHEATSHEET closures, mutation, loops, destructuring, stdlib, try/catch, match, optional chaining, and pipelines.
const cases = [{'case_id': 'HID-INT-001', 'title': 'closure counter mutates captured state', 'src': 'let mut x = 0; fn next() { x = x + 1; x }; next(); next(); next()', 'expected': 3}, {'case_id': 'HID-INT-002', 'title': 'nested closure lexical shadow', 'src': 'let x = 10; fn outer(x) { fn inner(y) { x + y }; inner }; let f = outer(5); f(7)', 'expected': 12}, {'case_id': 'HID-INT-003', 'title': 'loop continue accumulates odds', 'src': 'let mut s = 0; for x in range(0, 7) { if x % 2 == 0 { continue }; s = s + x }; s', 'expected': 9}, {'case_id': 'HID-INT-004', 'title': 'loop break stops at threshold', 'src': 'let mut s = 0; for x in range(0, 10) { if x == 5 { break }; s = s + x }; s', 'expected': 10}, {'case_id': 'HID-INT-005', 'title': 'destructuring entries branch', 'src': 'let mut total = 0; for [k,v] in entries({a:1,b:2,c:3}) { if v >= 2 { total = total + v } }; total', 'expected': 5}, {'case_id': 'HID-INT-006', 'title': 'default parameter with interpolation', 'src': 'fn greet(name, greeting = "hi") { "{greeting} {name}" }; greet("Ada")', 'expected': 'hi Ada'}, {'case_id': 'HID-INT-007', 'title': 'rest parameter reduce', 'src': 'fn total(...nums) { reduce(nums, (a,b) => a + b, 0) }; total(1,2,3,4)', 'expected': 10}, {'case_id': 'HID-INT-008', 'title': 'try catch recovers conversion error', 'src': 'try { int("bad") } catch e { 42 }', 'expected': 42}, {'case_id': 'HID-INT-009', 'title': 'optional chain through nil', 'src': 'let u = {name:"Ada"}; u?.missing?.city', 'expected': null}, {'case_id': 'HID-INT-010', 'title': 'do while boundary', 'src': 'let mut x = 0; do { x = x + 1 } while x < 3; x', 'expected': 3}, {'case_id': 'HID-INT-011', 'title': 'do until boundary', 'src': 'let mut x = 0; do { x = x + 1 } until x >= 4; x', 'expected': 4}, {'case_id': 'HID-INT-012', 'title': 'match range score', 'src': 'let grade = match 87 { 90..100 => "A", 80..89 => "B", _ => "C" }; grade', 'expected': 'B'}, {'case_id': 'HID-INT-013', 'title': 'string chars map ord', 'src': 'sum(map(chars("ABC"), ch => ord(ch)))', 'expected': 198}, {'case_id': 'HID-INT-014', 'title': 'nested collection flat map', 'src': 'sum(map(flat([[1,2],[3],[4]]), x => x * 2))', 'expected': 20}, {'case_id': 'HID-INT-015', 'title': 'pipeline captures outer binding', 'src': 'let k = 2; [1,2,3] |> map(x => x * k) |> sum()', 'expected': 12}, {'case_id': 'HID-INT-016', 'title': 'recursive closure from factory', 'src': 'fn make(step) { fn walk(n) { if n <= 0 { return 0 }; return step + walk(n - 1) }; walk }; let f = make(3); f(4)', 'expected': 12}] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);
function runExpr(src: string): any { return interpretWithEnv(parse(lex(src)), createEnv()); }
console.log("Hidden integration tests:");
for (const c of cases) { try { const actual = runExpr(c.src); assert(deepEqual(actual, c.expected), `${c.case_id} expected ${JSON.stringify(c.expected)}, got ${JSON.stringify(actual)}`); pass(); } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); } }
console.log(`  ${passed} passed, ${failed} failed`);
