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

// Public smoke tests: codegen basics. Case count: 8.
const cases = [
  ["SMOKE-CG-001", "let result = 1 + 2", 3],
  ["SMOKE-CG-002", "let result = sum([1,2,3])", 6],
  ["SMOKE-CG-003", "fn add(a,b){ a+b }; let result = add(2,5)", 7],
  ["SMOKE-CG-004", "let result = if true { 1 } else { 0 }", 1],
  ["SMOKE-CG-005", "let result = len(\"abc\")", 3],
  ["SMOKE-CG-006", "let result = map([1,2], x => x+1)[1]", 3],
  ["SMOKE-CG-007", "let result = {a:2}.a", 2],
  ["SMOKE-CG-008", "let result = \"ha\" * 2", "haha"],
] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);
const { generateIR } = requireArc(`${arcRoot}/compiler/src/ir.js`);
const { generateJS } = requireArc(`${arcRoot}/compiler/src/codegen-js.js`);
function program(src: string): any { return parse(lex(src)); }
function runGenerated(src: string): any { const js = generateJS(generateIR(program(src))); return new Function(`${js}\n; return (typeof result !== "undefined") ? result : undefined;`)(); }
for (const [id, src, expected] of cases) { try { const interpreted = interpretWithEnv(program(src), createEnv()); const generated = runGenerated(src); assert(deepEqual(interpreted, expected), `${id} interpreter mismatch`); assert(deepEqual(generated, expected), `${id} generated mismatch`); pass(); } catch (e: any) { fail(String(id), e); } }
console.log(`  ${passed} passed, ${failed} failed`);
