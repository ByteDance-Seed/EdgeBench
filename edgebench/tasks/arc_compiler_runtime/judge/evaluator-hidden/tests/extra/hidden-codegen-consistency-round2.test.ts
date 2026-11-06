// Hidden evaluator: codegen/interpreter consistency round 2
// Case count: 40
// Provenance: SPEC_CONFIRMED by public semantics/CHEATSHEET for closures, recursion, mutation, stdlib callbacks, pipelines, match, strings, and codegen consistency.
import { createRequire } from "module";
import { fileURLToPath } from "url";
export let passed = 0;
export let failed = 0;
const fallbackRoot = fileURLToPath(new URL("../../..", import.meta.url));
const arcRoot = process.env.ARC_TEST_ROOT ?? fallbackRoot;
const requireArc = createRequire(import.meta.url);
function pass() { passed++; }
function fail(name: string, e: any) { failed++; if (failed <= 10) console.error(`  FAIL: ${name} — ${e?.message ?? e}`); }
function deepEqual(a: any, b: any): boolean { return JSON.stringify(a) === JSON.stringify(b); }
function assert(cond: boolean, msg: string) { if (!cond) throw new Error(msg); }
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);
const { generateIR } = requireArc(`${arcRoot}/compiler/src/ir.js`);
const { generateJS } = requireArc(`${arcRoot}/compiler/src/codegen-js.js`);
function program(src: string): any { return parse(lex(src)); }
function runInterpreted(src: string): any { return interpretWithEnv(program(src), createEnv()); }
function runGenerated(src: string): any { const js = generateJS(generateIR(program(src))); assert(typeof js === "string" && js.length > 0, "generated JS is non-empty"); return new Function(`${js}
; return (typeof result !== "undefined") ? result : undefined;`)(); }
const cases = [
  {
    "case_id": "HID-CG2-001",
    "title": "closure with captured multiplier",
    "src": "fn make(k) { fn inner(x) => x * k; inner }; let by4 = make(4); let result = by4(7)",
    "expected": 28
  },
  {
    "case_id": "HID-CG2-002",
    "title": "recursive triangular",
    "src": "fn tri(n) => if n <= 0 { 0 } el { n + tri(n - 1) }; let result = tri(10)",
    "expected": 55
  },
  {
    "case_id": "HID-CG2-003",
    "title": "nested branch mutation",
    "src": "let mut total = 0; for x in [1,2,3,4] { if x % 2 == 0 { total = total + x * 3 } el { total = total + 1 } }; let result = total",
    "expected": 20
  },
  {
    "case_id": "HID-CG2-004",
    "title": "map filter reduce callback capture",
    "src": "let limit = 3; let result = reduce(filter([1,2,3,4,5], x => x > limit), (a,b) => a + b, 0)",
    "expected": 9
  },
  {
    "case_id": "HID-CG2-005",
    "title": "string interpolation arithmetic",
    "src": "let x = 4; let result = \"v={x * x + 1}\"",
    "expected": "v=17"
  },
  {
    "case_id": "HID-CG2-006",
    "title": "array index assignment sequence",
    "src": "let mut xs = [1,2,3]; xs[1] = xs[0] + xs[2]; let result = xs[1]",
    "expected": 4
  },
  {
    "case_id": "HID-CG2-007",
    "title": "object member assignment sequence",
    "src": "let mut user = {score:2}; user.score = user.score * 5; let result = user.score",
    "expected": 10
  },
  {
    "case_id": "HID-CG2-008",
    "title": "range pipeline sum",
    "src": "let result = range(0, 6) |> filter(x => x % 2 == 1) |> map(x => x * x) |> sum()",
    "expected": 35
  },
  {
    "case_id": "HID-CG2-009",
    "title": "do until accumulation",
    "src": "let mut x = 0; let mut s = 0; do { x = x + 1; s = s + x } until x >= 5; let result = s",
    "expected": 15
  },
  {
    "case_id": "HID-CG2-010",
    "title": "short circuit avoids division",
    "src": "let result = false and (1 / 0 > 0)",
    "expected": false
  },
  {
    "case_id": "HID-CG2-011",
    "title": "nested function shadows outer",
    "src": "let x = 1; fn outer() { let x = 10; fn inner() => x + 2; inner() }; let result = outer() + x",
    "expected": 13
  },
  {
    "case_id": "HID-CG2-012",
    "title": "entries loop sum values",
    "src": "let mut total = 0; for [k, v] in entries({a:2,b:4,c:8}) { total = total + v }; let result = total",
    "expected": 14
  },
  {
    "case_id": "HID-CG2-013",
    "title": "match range result",
    "src": "let result = match 42 { 0..9 => \"digit\", 10..99 => \"two\", _ => \"many\" }",
    "expected": "two"
  },
  {
    "case_id": "HID-CG2-014",
    "title": "find with callback",
    "src": "let result = find([1,3,6,10], x => x > 5)",
    "expected": 6
  },
  {
    "case_id": "HID-CG2-015",
    "title": "all any combination",
    "src": "let result = all([2,4,6], x => x % 2 == 0) and any([1,3,4], y => y > 3)",
    "expected": true
  },
  {
    "case_id": "HID-CG2-016",
    "title": "zip reduce product",
    "src": "let result = reduce(zip([1,2,3],[10,20,30]), (acc,p) => acc + p[0] * p[1], 0)",
    "expected": 140
  },
  {
    "case_id": "HID-CG2-017",
    "title": "tail head composition",
    "src": "let result = head(tail([7,8,9]))",
    "expected": 8
  },
  {
    "case_id": "HID-CG2-018",
    "title": "concat reverse last",
    "src": "let result = last(reverse(concat([1,2],[3,4])))",
    "expected": 4
  },
  {
    "case_id": "HID-CG2-019",
    "title": "default parameter",
    "src": "fn greet(name = \"Arc\") { \"hi {name}\" }; let result = greet()",
    "expected": "hi Arc"
  },
  {
    "case_id": "HID-CG2-020",
    "title": "rest reduce",
    "src": "fn total(...xs) { reduce(xs, (a,b) => a + b, 0) }; let result = total(1,2,3,4,5)",
    "expected": 15
  },
  {
    "case_id": "HID-CG2-021",
    "title": "recursive pow2 variant 21",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(4)",
    "expected": 16
  },
  {
    "case_id": "HID-CG2-022",
    "title": "recursive pow2 variant 22",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(5)",
    "expected": 32
  },
  {
    "case_id": "HID-CG2-023",
    "title": "recursive pow2 variant 23",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(6)",
    "expected": 64
  },
  {
    "case_id": "HID-CG2-024",
    "title": "recursive pow2 variant 24",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(7)",
    "expected": 128
  },
  {
    "case_id": "HID-CG2-025",
    "title": "recursive pow2 variant 25",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(8)",
    "expected": 256
  },
  {
    "case_id": "HID-CG2-026",
    "title": "recursive pow2 variant 26",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(9)",
    "expected": 512
  },
  {
    "case_id": "HID-CG2-027",
    "title": "recursive pow2 variant 27",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(10)",
    "expected": 1024
  },
  {
    "case_id": "HID-CG2-028",
    "title": "recursive pow2 variant 28",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(4)",
    "expected": 16
  },
  {
    "case_id": "HID-CG2-029",
    "title": "recursive pow2 variant 29",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(5)",
    "expected": 32
  },
  {
    "case_id": "HID-CG2-030",
    "title": "recursive pow2 variant 30",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(6)",
    "expected": 64
  },
  {
    "case_id": "HID-CG2-031",
    "title": "recursive pow2 variant 31",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(7)",
    "expected": 128
  },
  {
    "case_id": "HID-CG2-032",
    "title": "recursive pow2 variant 32",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(8)",
    "expected": 256
  },
  {
    "case_id": "HID-CG2-033",
    "title": "recursive pow2 variant 33",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(9)",
    "expected": 512
  },
  {
    "case_id": "HID-CG2-034",
    "title": "recursive pow2 variant 34",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(10)",
    "expected": 1024
  },
  {
    "case_id": "HID-CG2-035",
    "title": "recursive pow2 variant 35",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(4)",
    "expected": 16
  },
  {
    "case_id": "HID-CG2-036",
    "title": "recursive pow2 variant 36",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(5)",
    "expected": 32
  },
  {
    "case_id": "HID-CG2-037",
    "title": "recursive pow2 variant 37",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(6)",
    "expected": 64
  },
  {
    "case_id": "HID-CG2-038",
    "title": "recursive pow2 variant 38",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(7)",
    "expected": 128
  },
  {
    "case_id": "HID-CG2-039",
    "title": "recursive pow2 variant 39",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(8)",
    "expected": 256
  },
  {
    "case_id": "HID-CG2-040",
    "title": "recursive pow2 variant 40",
    "src": "fn pow2(n) => if n == 0 { 1 } el { 2 * pow2(n - 1) }; let result = pow2(9)",
    "expected": 512
  }
] as const;
console.log("Hidden codegen consistency round2 tests:");
for (const c of cases) {
  try {
    const interpreted = runInterpreted(c.src);
    const generated = runGenerated(c.src);
    assert(deepEqual(interpreted, c.expected), `${c.case_id} interpreter expected ${JSON.stringify(c.expected)}, got ${JSON.stringify(interpreted)}`);
    assert(deepEqual(generated, c.expected), `${c.case_id} generated expected ${JSON.stringify(c.expected)}, got ${JSON.stringify(generated)}`);
    pass();
  } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); }
}
console.log(`  ${passed} passed, ${failed} failed`);
