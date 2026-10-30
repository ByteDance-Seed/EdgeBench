// Stage: Type System
// Case count: 8
// Provenance: SPEC_CONFIRMED from CHEATSHEET scoping, mutability, functions, destructuring, and match forms plus existing semantic tests.
// Included in official scoring: YES. Does not depend on evaluator-only artifacts or network.
import { createRequire } from "module";

export let passed = 0;
export let failed = 0;

const arcRoot = process.env.ARC_TEST_ROOT ?? new URL("../..", import.meta.url).pathname;
const requireArc = createRequire(import.meta.url);
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { analyze } = requireArc(`${arcRoot}/compiler/src/semantic.js`);

function diagnostics(source: string): any[] { return analyze(parse(lex(source))); }
function errors(source: string): any[] { return diagnostics(source).filter((d: any) => d.level === "error"); }
function warnings(source: string): any[] { return diagnostics(source).filter((d: any) => d.level === "warning"); }
function assert(cond: boolean, msg: string) { if (cond) passed++; else { failed++; console.error(`  FAIL: ${msg}`); } }
function test(name: string, fn: () => void) { try { fn(); } catch (e: any) { failed++; console.error(`  FAIL: ${name} — ${e?.message ?? e}`); } }

console.log("Round2 Strengthened Type System Tests:");

test("nested function can read outer binding", () => {
  assert(errors("let x = 1\nfn outer() { fn inner() => x; inner() }\nouter()").length === 0, "outer binding is visible in nested function");
});

test("sibling function local remains invisible", () => {
  assert(errors("fn a() { let secret = 1 }\nfn b() => secret").some((d: any) => String(d.message).includes("Undefined")), "sibling-local name is rejected");
});

test("immutable reassignment is rejected", () => {
  assert(errors("let x = 1\nx = 2").some((d: any) => String(d.message).includes("Cannot reassign immutable")), "immutable reassignment diagnostic");
});

test("mutable reassignment inside branch is accepted", () => {
  assert(errors("let mut x = 1\nif true { x = x + 1 }\nx").length === 0, "mutable assignment accepted across nested block");
});

test("wrong arity on user function is rejected", () => {
  assert(errors("fn add(a, b) => a + b\nadd(1, 2, 3)").some((d: any) => String(d.message).includes("expects 2")), "too many args rejected");
});

test("wildcard makes match exhaustive", () => {
  assert(warnings("match 1 { 1 => 1, _ => 0 }").length === 0, "wildcard match has no exhaustiveness warning");
});

test("object destructuring introduces field names", () => {
  assert(errors("let {name, age} = {name: \"Arc\", age: 1}\nname\nage").length === 0, "destructured names are visible");
});

test("mutually recursive functions are hoisted", () => {
  assert(errors("fn even(n) => if n == 0 { true } el { odd(n - 1) }\nfn odd(n) => if n == 0 { false } el { even(n - 1) }\neven(4)").length === 0, "mutual recursion resolves names");
});

console.log(`  ${passed} passed, ${failed} failed`);
