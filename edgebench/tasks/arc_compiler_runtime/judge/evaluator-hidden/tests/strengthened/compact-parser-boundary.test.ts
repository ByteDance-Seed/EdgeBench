import { createRequire } from "module";
import { fileURLToPath } from "url";

export let passed = 0;
export let failed = 0;

const fallbackRoot = import.meta.url.includes("/tests/strengthened/")
  ? fileURLToPath(new URL("../..", import.meta.url))
  : fileURLToPath(new URL("../agent-start/", import.meta.url));
const arcRoot = process.env.ARC_TEST_ROOT ?? fallbackRoot;
const requireArc = createRequire(import.meta.url);

function pass() { passed++; }
function fail(name: string, e: any) { failed++; if (failed <= 8) console.error(`  FAIL: ${name} — ${e?.message ?? e}`); }
function deepEqual(a: any, b: any): boolean { return JSON.stringify(a) === JSON.stringify(b); }
function assert(cond: boolean, msg: string) { if (!cond) throw new Error(msg); }

// Compact high-signal official candidate file
// Module: parser-boundary
// Case count: 25
// SPEC_CONFIRMED from solver-visible CHEATSHEET.md and existing parser tests.
// Deterministic/offline/no external reference artifact/no hidden data. Included in compact official scoring after promotion.
const cases = [
  {
    "case_id": "CHS-PB-001",
    "title": "exponentiation nests under multiplication and addition",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET arithmetic precedence",
    "expected_behavior": "AST outer node is addition BinaryExpr and preserves exponentiation subtree",
    "mutation_or_shallow_solution_killed": "flat precedence parser",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "1 + 2 * 3 ** 2",
    "expected_kind": "BinaryExpr",
    "json_must_contain": [
      "**"
    ]
  },
  {
    "case_id": "CHS-PB-002",
    "title": "left-associative pipeline chain",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET pipeline operator and stdlib calls",
    "expected_behavior": "AST is nested PipelineExpr chain",
    "mutation_or_shallow_solution_killed": "parser treats pipe as binary arithmetic or call syntax",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "[1,2,3] |> map(x => x + 1) |> sum()",
    "expected_kind": "PipelineExpr",
    "json_must_contain": [
      "PipelineExpr",
      "map",
      "sum"
    ]
  },
  {
    "case_id": "CHS-PB-003",
    "title": "call-index-member-call-member chain",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Existing parser tests and CHEATSHEET member/index/call chains",
    "expected_behavior": "AST outer node is member access value",
    "mutation_or_shallow_solution_killed": "parser truncates chained postfix operations",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "factory(1, 2)[0].next(3).value",
    "expected_kind": "MemberExpr",
    "json_must_contain": [
      "value",
      "CallExpr"
    ]
  },
  {
    "case_id": "CHS-PB-004",
    "title": "filtered list comprehension",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET list comprehensions with if filters",
    "expected_behavior": "AST is ListComprehension with filter",
    "mutation_or_shallow_solution_killed": "parser ignores comprehension filter clause",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "[x * x for x in range(0, 6) if x % 2 == 0]",
    "expected_kind": "ListComprehension",
    "json_must_contain": [
      "filter",
      "range"
    ]
  },
  {
    "case_id": "CHS-PB-005",
    "title": "two-generator list comprehension",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET multiple-generator comprehensions",
    "expected_behavior": "AST preserves multiple generators",
    "mutation_or_shallow_solution_killed": "parser only supports one generator",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "[[x, y] for x in xs for y in ys]",
    "expected_kind": "ListComprehension",
    "json_must_contain": [
      "generators",
      "xs",
      "ys"
    ]
  },
  {
    "case_id": "CHS-PB-006",
    "title": "match expression with numeric range and wildcard",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET match with range and wildcard",
    "expected_behavior": "AST is MatchExpr and retains range arm",
    "mutation_or_shallow_solution_killed": "parser lacks range arm or wildcard arm",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "match code { 200 => \"ok\", 400..499 => \"client\", _ => \"other\" }",
    "expected_kind": "MatchExpr",
    "json_must_contain": [
      "client",
      "other"
    ]
  },
  {
    "case_id": "CHS-PB-007",
    "title": "string literal union type declaration",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET declaration-based type aliases and union syntax",
    "expected_behavior": "AST is TypeStmt with string literal union members",
    "mutation_or_shallow_solution_killed": "parser only accepts identifier type names",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "type Status = \"active\" | \"inactive\" | \"banned\"",
    "expected_kind": "TypeStmt",
    "json_must_contain": [
      "active",
      "banned"
    ]
  },
  {
    "case_id": "CHS-PB-008",
    "title": "regex-backed string type declaration",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET matching regex type declaration",
    "expected_behavior": "AST is TypeStmt with matching regex constraint",
    "mutation_or_shallow_solution_killed": "parser drops matching clause",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "type Email = String matching /^[^@]+@[^@]+$/",
    "expected_kind": "TypeStmt",
    "json_must_contain": [
      "Email",
      "matching"
    ]
  },
  {
    "case_id": "CHS-PB-009",
    "title": "function rest parameter declaration",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET rest parameters and reduce",
    "expected_behavior": "AST is FunctionStmt with rest parameter",
    "mutation_or_shallow_solution_killed": "parser rejects variadic parameter marker",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "fn sum(...nums) { reduce(nums, (a, b) => a + b, 0) }",
    "expected_kind": "FunctionStmt",
    "json_must_contain": [
      "nums",
      "reduce"
    ]
  },
  {
    "case_id": "CHS-PB-010",
    "title": "array destructuring with rest binding",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET array destructuring rest binding",
    "expected_behavior": "AST is LetStmt with destructuring target",
    "mutation_or_shallow_solution_killed": "parser treats destructuring target as expression only",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "let [head, ...tail] = [1, 2, 3, 4]",
    "expected_kind": "LetStmt",
    "json_must_contain": [
      "head",
      "tail"
    ]
  },
  {
    "case_id": "CHS-PB-011",
    "title": "object destructuring with rest binding",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET object destructuring rest binding",
    "expected_behavior": "AST is LetStmt with object destructuring target",
    "mutation_or_shallow_solution_killed": "parser loses object rest binding",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "let {name, ...rest} = {name: \"Arc\", age: 1, lang: \"arc\"}",
    "expected_kind": "LetStmt",
    "json_must_contain": [
      "name",
      "rest"
    ]
  },
  {
    "case_id": "CHS-PB-012",
    "title": "destructuring entries in for loop",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET entries(map) and destructuring in for loops",
    "expected_behavior": "AST is ForStmt with destructured loop target",
    "mutation_or_shallow_solution_killed": "parser only allows identifier loop target",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "for [key, val] in entries(scores) { print(\"{key}:{val}\") }",
    "expected_kind": "ForStmt",
    "json_must_contain": [
      "entries",
      "key",
      "val"
    ]
  },
  {
    "case_id": "CHS-PB-013",
    "title": "object destructuring in function parameter",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET destructuring in function parameters",
    "expected_behavior": "AST preserves destructured function parameter",
    "mutation_or_shallow_solution_killed": "parser rejects object pattern parameters",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "fn greet({name, age}) { \"Hi {name}, age {age}\" }",
    "expected_kind": "FunctionStmt",
    "json_must_contain": [
      "name",
      "age"
    ]
  },
  {
    "case_id": "CHS-PB-014",
    "title": "array destructuring in function parameter",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET destructuring in function parameters",
    "expected_behavior": "AST preserves rest array parameter",
    "mutation_or_shallow_solution_killed": "parser rejects array pattern parameters",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "fn process([head, ...tail]) { head + len(tail) }",
    "expected_kind": "FunctionStmt",
    "json_must_contain": [
      "head",
      "tail"
    ]
  },
  {
    "case_id": "CHS-PB-015",
    "title": "optional chaining through nested member access",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET optional chaining",
    "expected_behavior": "AST represents optional member chain",
    "mutation_or_shallow_solution_killed": "parser parses ? as ternary or fails optional access",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "user?.address?.zip",
    "expected_kind": "MemberExpr",
    "json_must_contain": [
      "address",
      "zip"
    ]
  },
  {
    "case_id": "CHS-PB-016",
    "title": "nil-coalescing fallback expression",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET nil-coalescing operator",
    "expected_behavior": "AST is BinaryExpr for ?? fallback",
    "mutation_or_shallow_solution_killed": "parser misses ?? precedence",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "user.name ?? \"anonymous\"",
    "expected_kind": "BinaryExpr",
    "json_must_contain": [
      "??",
      "anonymous"
    ]
  },
  {
    "case_id": "CHS-PB-017",
    "title": "default function parameter",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET default parameters",
    "expected_behavior": "AST stores default parameter expression",
    "mutation_or_shallow_solution_killed": "parser rejects parameter defaults",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "fn greet(name = \"world\") { \"hi {name}\" }",
    "expected_kind": "FunctionStmt",
    "json_must_contain": [
      "world"
    ]
  },
  {
    "case_id": "CHS-PB-018",
    "title": "inline semicolon statement boundary",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Existing round2 semicolon boundary test",
    "expected_behavior": "program has three statements",
    "mutation_or_shallow_solution_killed": "parser collapses semicolon-delimited statements",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "program",
    "src": "let a = 1; let b = 2; a + b",
    "expected_kind": "Program",
    "json_must_contain": [
      "stmts"
    ]
  },
  {
    "case_id": "CHS-PB-019",
    "title": "line and trailing comments before statements",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET comments and existing lexer tests",
    "expected_behavior": "comments do not erase following declarations",
    "mutation_or_shallow_solution_killed": "lexer/parser treats comments as tokens",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "program",
    "src": "# lead\nlet x = 1 // trailing\nlet y = x + 2",
    "expected_kind": "Program",
    "json_must_contain": [
      "x",
      "y"
    ]
  },
  {
    "case_id": "CHS-PB-020",
    "title": "string interpolation with function call",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET interpolation expressions and function calls",
    "expected_behavior": "string expression retains interpolation payload",
    "mutation_or_shallow_solution_killed": "lexer drops interpolation expression",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "\"total: {sum([1,2,3])}\"",
    "expected_kind": "StringLiteral",
    "json_must_contain": [
      "sum"
    ]
  },
  {
    "case_id": "CHS-PB-021",
    "title": "indexing inside interpolation",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET indexing in interpolation",
    "expected_behavior": "string expression retains index expression",
    "mutation_or_shallow_solution_killed": "lexer/parser cannot tokenize indexed interpolation",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "\"first: {items[0]}\"",
    "expected_kind": "StringLiteral",
    "json_must_contain": [
      "items"
    ]
  },
  {
    "case_id": "CHS-PB-022",
    "title": "rich match object pattern arm",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET rich match patterns and object destructuring",
    "expected_behavior": "AST is MatchExpr with object pattern arm",
    "mutation_or_shallow_solution_killed": "parser accepts only literal match arms",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "match user { {name, age} => name, _ => \"unknown\" }",
    "expected_kind": "MatchExpr",
    "json_must_contain": [
      "unknown",
      "name"
    ]
  },
  {
    "case_id": "CHS-PB-023",
    "title": "selective module use declaration",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET selective module imports",
    "expected_behavior": "AST is UseStmt with selected names",
    "mutation_or_shallow_solution_killed": "parser supports only bare use statements",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "use math { sqrt, PI }",
    "expected_kind": "UseStmt",
    "json_must_contain": [
      "sqrt",
      "PI"
    ]
  },
  {
    "case_id": "CHS-PB-024",
    "title": "path import declaration",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET import module from path",
    "expected_behavior": "AST is ImportStmt with path string",
    "mutation_or_shallow_solution_killed": "parser lacks import-from form",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "stmt",
    "src": "import regex from \"stdlib/regex\"",
    "expected_kind": "ImportStmt",
    "json_must_contain": [
      "regex",
      "stdlib/regex"
    ]
  },
  {
    "case_id": "CHS-PB-025",
    "title": "nested ternary-like if expression boundary",
    "module": "parser-boundary",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET if/else control flow expressions",
    "expected_behavior": "AST is IfExpr and preserves else-if boundary",
    "mutation_or_shallow_solution_killed": "parser flattens else-if incorrectly",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "mode": "expr",
    "src": "if score >= 90 { \"A\" } else if score >= 80 { \"B\" } else { \"C\" }",
    "expected_kind": "IfExpr",
    "json_must_contain": [
      "score",
      "B",
      "C"
    ]
  }
] as const;

const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);

function selectNode(program: any, mode: string): any {
  if (mode === "program") return program;
  const first = program.stmts?.[0];
  if (mode === "stmt") return first;
  return first?.expr ?? first;
}

console.log("Compact parser boundary tests:");
for (const c of cases) {
  try {
    const program = parse(lex(c.src));
    const node = selectNode(program, c.mode);
    const encoded = JSON.stringify(node ?? program);
    if (c.expected_kind !== "Program") {
      assert(node?.kind === c.expected_kind, `${c.case_id} expected kind ${c.expected_kind}, got ${node?.kind}`);
    } else {
      assert(Array.isArray(program.stmts), `${c.case_id} expected Program with stmts`);
    }
    for (const needle of c.json_must_contain) {
      assert(encoded.includes(needle), `${c.case_id} AST missing ${needle}`);
    }
    pass();
  } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); }
}
console.log(`  ${passed} passed, ${failed} failed`);
