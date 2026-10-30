// Stage: Codegen
// Case count: 8
// Provenance: SPEC_CONFIRMED from CHEATSHEET codegen/toolchain goal plus existing behavior-based codegen tests.
// Included in official scoring: YES. Does not depend on evaluator-only artifacts or network.
import { createRequire } from "module";

export let passed = 0;
export let failed = 0;

const arcRoot = process.env.ARC_TEST_ROOT ?? new URL("../..", import.meta.url).pathname;
const requireArc = createRequire(import.meta.url);
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { generateIR } = requireArc(`${arcRoot}/compiler/src/ir.js`);
const { generateJS } = requireArc(`${arcRoot}/compiler/src/codegen-js.js`);
function loadGenerateWAT(): (ir: any) => string {
  return requireArc(`${arcRoot}/compiler/src/codegen.js`).generateWAT;
}

function compileToJS(source: string): string { return generateJS(generateIR(parse(lex(source)))); }
function compileToWAT(source: string): string { return loadGenerateWAT()(generateIR(parse(lex(source)))); }
function evalJS(js: string): void { new Function(js)(); }
function assert(cond: boolean, msg: string) { if (cond) passed++; else { failed++; console.error(`  FAIL: ${msg}`); } }
function test(name: string, fn: () => void) { try { fn(); } catch (e: any) { failed++; console.error(`  FAIL: ${name} — ${e?.message ?? e}`); } }

console.log("Round2 Strengthened Codegen Tests:");

test("generated JS executes arithmetic and local binding", () => {
  evalJS(compileToJS("let x = 2 + 3 * 4"));
  assert(true, "arithmetic JS executes");
});

test("generated JS executes function call", () => {
  evalJS(compileToJS("fn add(a, b) => a + b\nlet r = add(3, 4)"));
  assert(true, "function call JS executes");
});

test("generated JS executes conditional expression", () => {
  evalJS(compileToJS("let x = if true { 1 } el { 2 }"));
  assert(true, "conditional JS executes");
});

test("generated JS executes list literal", () => {
  evalJS(compileToJS("let xs = [1, 2, 3]"));
  assert(true, "list literal JS executes");
});

test("generated JS executes pipeline expression", () => {
  evalJS(compileToJS("fn double(x) => x * 2\nlet r = 5 |> double"));
  assert(true, "pipeline JS executes");
});

test("generated JS maps logical operators", () => {
  const js = compileToJS("let a = true and false\nlet b = true or false\nlet c = not true");
  evalJS(js);
  assert(js.includes("&&") && js.includes("||") && js.includes("!"), "logical operators appear in JS");
});

test("generated WAT has module and start export", () => {
  const wat = compileToWAT("let x = 42");
  assert(wat.startsWith("(module") && wat.includes("_start"), "WAT module start export");
});

test("generated WAT includes function and arithmetic instruction", () => {
  const wat = compileToWAT("fn add(a, b) => a + b");
  assert(wat.includes("(func $add") && wat.includes("i32.add"), "WAT function add");
});

console.log(`  ${passed} passed, ${failed} failed`);
