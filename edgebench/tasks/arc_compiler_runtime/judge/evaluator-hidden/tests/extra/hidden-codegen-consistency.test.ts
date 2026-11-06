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

// Hidden evaluator file: codegen/interpreter consistency
// Case count: 12
// Provenance: SPEC_CONFIRMED from CHEATSHEET functions, closures, recursion, stdlib, pipeline, match, optional chaining, and mutation.
const cases = [{'case_id': 'HID-CG-001', 'title': 'closure captures multiplier', 'src': 'fn mul(k) { fn inner(x) { x * k }; inner }; let f = mul(4); let result = f(6)', 'expected': 24}, {'case_id': 'HID-CG-002', 'title': 'recursive sum with explicit returns', 'src': 'fn s(n) { if n <= 0 { return 0 }; return n + s(n - 1) }; let result = s(6)', 'expected': 21}, {'case_id': 'HID-CG-003', 'title': 'short circuit protects side effect', 'src': 'let mut x = 0; fn bump() { x = x + 1; true }; let ok = true or bump(); let result = x', 'expected': 0}, {'case_id': 'HID-CG-004', 'title': 'while break return interaction', 'src': 'let mut x = 0; while true { x = x + 1; if x == 5 { break } }; let result = x', 'expected': 5}, {'case_id': 'HID-CG-005', 'title': 'nested map filter sum', 'src': 'let result = sum(map(filter(range(0, 8), x => x % 2 == 1), x => x * 3))', 'expected': 48}, {'case_id': 'HID-CG-006', 'title': 'string composition', 'src': 'let result = join(map(split("a,b,c", ","), x => upper(x)), "-")', 'expected': 'A-B-C'}, {'case_id': 'HID-CG-007', 'title': 'object member mutation', 'src': 'let mut o = {n: 1}; o.n = o.n + 9; let result = o.n', 'expected': 10}, {'case_id': 'HID-CG-008', 'title': 'match range fallback', 'src': 'let result = match 503 { 400..499 => "client", 500..599 => "server", _ => "other" }', 'expected': 'server'}, {'case_id': 'HID-CG-009', 'title': 'pipeline with take drop', 'src': 'let result = range(0, 10) |> drop(3) |> take(4) |> sum()', 'expected': 18}, {'case_id': 'HID-CG-010', 'title': 'zip reduce product sum', 'src': 'let result = reduce(zip([1,2,3],[10,20,30]), (acc, p) => acc + p[0] * p[1], 0)', 'expected': 140}, {'case_id': 'HID-CG-011', 'title': 'optional chaining nil path', 'src': 'let user = {profile:{name:"Ada"}}; let result = user?.missing?.name', 'expected': null}, {'case_id': 'HID-CG-012', 'title': 'chars ord reduce', 'src': 'let result = reduce(chars("ABC"), (acc, ch) => acc + ord(ch), 0)', 'expected': 198}] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);
const { generateIR } = requireArc(`${arcRoot}/compiler/src/ir.js`);
const { generateJS } = requireArc(`${arcRoot}/compiler/src/codegen-js.js`);
function program(src: string): any { return parse(lex(src)); }
function runInterpreted(src: string): any { return interpretWithEnv(program(src), createEnv()); }
function runGenerated(src: string): any { const js = generateJS(generateIR(program(src))); assert(typeof js === "string" && js.length > 0, "generated JS is non-empty"); return new Function(`${js}\n; return (typeof result !== "undefined") ? result : undefined;`)(); }
console.log("Hidden codegen consistency tests:");
for (const c of cases) { try { const interpreted = runInterpreted(c.src); const generated = runGenerated(c.src); assert(deepEqual(interpreted, c.expected), `${c.case_id} interpreter expected ${JSON.stringify(c.expected)}, got ${JSON.stringify(interpreted)}`); assert(deepEqual(generated, c.expected), `${c.case_id} generated expected ${JSON.stringify(c.expected)}, got ${JSON.stringify(generated)}`); pass(); } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); } }
console.log(`  ${passed} passed, ${failed} failed`);
