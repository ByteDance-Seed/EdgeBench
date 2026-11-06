// Stage: Lexer/Parser
// Case count: 8
// Provenance: SPEC_CONFIRMED from CHEATSHEET comments, semicolons, strings, ranges, operators, member/index/call chains, type declarations, match forms.
// Included in official scoring: YES. Does not depend on evaluator-only artifacts or network.
import { createRequire } from "module";

export let passed = 0;
export let failed = 0;

const arcRoot = process.env.ARC_TEST_ROOT ?? new URL("../..", import.meta.url).pathname;
const requireArc = createRequire(import.meta.url);
const { lex, TokenType } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);

function assert(cond: boolean, msg: string) { if (cond) passed++; else { failed++; console.error(`  FAIL: ${msg}`); } }
function test(name: string, fn: () => void) { try { fn(); } catch (e: any) { failed++; console.error(`  FAIL: ${name} — ${e?.message ?? e}`); } }
function nonEof(src: string): any[] { return lex(src).filter((t: any) => t.type !== TokenType.EOF && t.type !== TokenType.Newline); }
function program(src: string): any { return parse(lex(src)); }
function expr(src: string): any { return program(src).stmts[0].expr; }
function stmt(src: string): any { return program(src).stmts[0]; }

console.log("Round2 Strengthened Lexer/Parser Tests:");

test("comments across lines preserve following declarations", () => {
  const toks = nonEof("# lead\nlet x = 1 // trailing\nlet y = x + 2");
  assert(toks.filter((t: any) => t.type === TokenType.Let).length === 2, "two let tokens remain after comments");
});

test("semicolons separate inline statements", () => {
  const ast = program("let a = 1; let b = 2; a + b");
  assert(ast.stmts.length === 3, "three semicolon-delimited statements");
});

test("range token does not consume following float literal", () => {
  const toks = nonEof("0..10 0.5");
  assert(toks[0].type === TokenType.Int && toks[1].type === TokenType.Range && toks[3].type === TokenType.Float, "range and float are distinct");
});

test("string escapes decode newline tab and unicode", () => {
  const toks = lex('"line\\n\\t\\u0041"');
  assert(toks[0].value.includes("\n") && toks[0].value.includes("\t") && toks[0].value.endsWith("A"), "escape decoding follows CHEATSHEET strings");
});

test("arithmetic precedence nests multiplication under addition", () => {
  const e = expr("1 + 2 * 3");
  assert(e.kind === "BinaryExpr" && e.op === "+" && e.right?.kind === "BinaryExpr" && e.right.op === "*", "multiplication binds tighter than addition");
});

test("call index member chain parses as outer member access", () => {
  const e = expr("factory(1, 2)[0].next(3).value");
  assert(e.kind === "MemberExpr" && e.property === "value", "outer expression is .value member access");
});

test("string literal union type declaration parses", () => {
  const s = stmt('type Status = "active" | "inactive" | "banned"');
  assert(s.kind === "TypeStmt", "union type declaration parsed");
});

test("match with numeric range and wildcard parses", () => {
  const e = expr('match code { 200 => "ok", 400..499 => "client", _ => "other" }');
  assert(e.kind === "MatchExpr" && JSON.stringify(e).includes("client"), "range and wildcard match parsed");
});

console.log(`  ${passed} passed, ${failed} failed`);
