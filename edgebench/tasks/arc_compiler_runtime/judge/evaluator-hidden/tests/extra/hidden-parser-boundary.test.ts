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

// Hidden evaluator file: parser boundary
// Case count: 12
// Provenance: SPEC_CONFIRMED from CHEATSHEET comments, functions, loops, match, modules, types, optional chaining, and pipeline.
const cases = [{'case_id': 'HID-PB-001', 'title': 'comments do not split statements', 'src': 'let x = 1 # hash comment\n// slash comment\nlet y = x + 2', 'expected_kind': 'Program', 'mustContain': ['x', 'y']}, {'case_id': 'HID-PB-002', 'title': 'nested optional member chain', 'src': 'user?.profile?.address?.city', 'expected_kind': 'Program', 'mustContain': ['user', 'city']}, {'case_id': 'HID-PB-003', 'title': 'default plus rest parameter function', 'src': 'fn collect(head, sep = ",", ...tail) { join(tail, sep) }', 'expected_kind': 'Program', 'mustContain': ['collect', 'tail', 'sep']}, {'case_id': 'HID-PB-004', 'title': 'do until loop boundary', 'src': 'do { x = x + 1 } until x >= 10', 'expected_kind': 'Program', 'mustContain': ['until', 'x']}, {'case_id': 'HID-PB-005', 'title': 'try catch requires named binding', 'src': 'try { int("bad") } catch err { print(err) }', 'expected_kind': 'Program', 'mustContain': ['err', 'int']}, {'case_id': 'HID-PB-006', 'title': 'where type declaration', 'src': 'type Age = Number where x >= 0 and x <= 150', 'expected_kind': 'Program', 'mustContain': ['Age', 'Number', 'where']}, {'case_id': 'HID-PB-007', 'title': 'module member call as expression', 'src': 'math.sqrt(16) + math.pow(2, 3)', 'expected_kind': 'Program', 'mustContain': ['math', 'sqrt', 'pow']}, {'case_id': 'HID-PB-008', 'title': 'range piped into composed call', 'src': '0..10 |> filter(x => x % 2 == 0) |> take(3)', 'expected_kind': 'Program', 'mustContain': ['filter', 'take']}, {'case_id': 'HID-PB-009', 'title': 'nested lambda with if expression', 'src': 'map(xs, x => if x > 0 { x } else { 0 })', 'expected_kind': 'Program', 'mustContain': ['map', 'else']}, {'case_id': 'HID-PB-010', 'title': 'deep literal nesting', 'src': '{user:{name:"Ada", roles:["admin", "ops"]}, flags:{active:true}}', 'expected_kind': 'Program', 'mustContain': ['Ada', 'roles', 'active']}, {'case_id': 'HID-PB-011', 'title': 'destructured entries loop', 'src': 'for [key, val] in entries(config) { print("{key}:{val}") }', 'expected_kind': 'Program', 'mustContain': ['entries', 'key', 'val']}, {'case_id': 'HID-PB-012', 'title': 'match with adjacent ranges', 'src': 'match n { 0..9 => "digit", 10..99 => "two", _ => "many" }', 'expected_kind': 'Program', 'mustContain': ['digit', 'many']}] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
console.log("Hidden parser boundary tests:");
for (const c of cases) {
  try {
    const ast = parse(lex(c.src));
    const encoded = JSON.stringify(ast);
    assert(Array.isArray(ast.stmts), `${c.case_id} expected Program stmts`);
    for (const needle of c.mustContain) assert(encoded.includes(needle), `${c.case_id} AST missing ${needle}`);
    pass();
  } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); }
}
console.log(`  ${passed} passed, ${failed} failed`);
