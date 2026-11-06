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
// Module: stdlib composition
// Case count: 30
// SPEC_CONFIRMED from solver-visible CHEATSHEET.md stdlib tables.
const cases = [
  {
    "case_id": "CHS-SL-001",
    "title": "filter map sum chain",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET map/filter/sum",
    "expected_behavior": "evaluates to 35",
    "mutation_or_shallow_solution_killed": "stdlib callbacks ignored or eager",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "sum(map(filter([1,2,3,4,5], x => x % 2 == 1), y => y * y))",
    "expected": 35
  },
  {
    "case_id": "CHS-SL-002",
    "title": "reduce with accumulator and item",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET reduce",
    "expected_behavior": "evaluates to 24",
    "mutation_or_shallow_solution_killed": "reduce argument order reversed",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "reduce([2,3,4], (acc, item) => acc * item, 1)",
    "expected": 24
  },
  {
    "case_id": "CHS-SL-003",
    "title": "fold init-first variant",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET fold",
    "expected_behavior": "evaluates to 19",
    "mutation_or_shallow_solution_killed": "fold implemented as reduce signature",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "fold([2,3,4], 10, (acc, item) => acc + item)",
    "expected": 19
  },
  {
    "case_id": "CHS-SL-004",
    "title": "find first matching item",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET find",
    "expected_behavior": "evaluates to 6",
    "mutation_or_shallow_solution_killed": "find returns last or boolean",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "find([1,3,6,8], x => x % 2 == 0)",
    "expected": 6
  },
  {
    "case_id": "CHS-SL-005",
    "title": "any positive predicate",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET any",
    "expected_behavior": "evaluates to true",
    "mutation_or_shallow_solution_killed": "any does not short-circuit predicate",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "any([1,2,3], x => x > 2)",
    "expected": true
  },
  {
    "case_id": "CHS-SL-006",
    "title": "all positive predicate",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET all",
    "expected_behavior": "evaluates to true",
    "mutation_or_shallow_solution_killed": "all checks only first element",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "all([2,4,6], x => x % 2 == 0)",
    "expected": true
  },
  {
    "case_id": "CHS-SL-007",
    "title": "sort then reverse",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET sort/reverse",
    "expected_behavior": "evaluates to [3, 2, 1]",
    "mutation_or_shallow_solution_killed": "sort mutates or reverse order wrong",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "reverse(sort([3,1,2]))",
    "expected": [
      3,
      2,
      1
    ]
  },
  {
    "case_id": "CHS-SL-008",
    "title": "head tail last composition",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET head/tail/last",
    "expected_behavior": "evaluates to 11",
    "mutation_or_shallow_solution_killed": "list slicing off by one",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "head(tail([9,8,7])) + last([1,2,3])",
    "expected": 11
  },
  {
    "case_id": "CHS-SL-009",
    "title": "take drop composition",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET take/drop",
    "expected_behavior": "evaluates to [1, 2, 3]",
    "mutation_or_shallow_solution_killed": "drop/take boundary error",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "take(drop([0,1,2,3,4], 1), 3)",
    "expected": [
      1,
      2,
      3
    ]
  },
  {
    "case_id": "CHS-SL-010",
    "title": "flat nested arrays",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET flat",
    "expected_behavior": "evaluates to [1, 2, 3, 4]",
    "mutation_or_shallow_solution_killed": "flat only removes first subarray",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "flat([[1],[2,3],[4]])",
    "expected": [
      1,
      2,
      3,
      4
    ]
  },
  {
    "case_id": "CHS-SL-011",
    "title": "zip preserves pair order",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET zip",
    "expected_behavior": "evaluates to [[1, \"a\"], [2, \"b\"]]",
    "mutation_or_shallow_solution_killed": "zip swaps pair order",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "zip([1,2],[\"a\",\"b\"])",
    "expected": [
      [
        1,
        "a"
      ],
      [
        2,
        "b"
      ]
    ]
  },
  {
    "case_id": "CHS-SL-012",
    "title": "enumerate zero-based indices",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET enumerate",
    "expected_behavior": "evaluates to [[0, \"a\"], [1, \"b\"], [2, \"c\"]]",
    "mutation_or_shallow_solution_killed": "enumerate starts at one",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "enumerate([\"a\",\"b\",\"c\"])",
    "expected": [
      [
        0,
        "a"
      ],
      [
        1,
        "b"
      ],
      [
        2,
        "c"
      ]
    ]
  },
  {
    "case_id": "CHS-SL-013",
    "title": "push returns new appended list",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET push",
    "expected_behavior": "evaluates to [1, 2, 3]",
    "mutation_or_shallow_solution_killed": "push mutates without returning list",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "push([1,2], 3)",
    "expected": [
      1,
      2,
      3
    ]
  },
  {
    "case_id": "CHS-SL-014",
    "title": "concat joins lists",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET concat",
    "expected_behavior": "evaluates to [1, 2, 3, 4]",
    "mutation_or_shallow_solution_killed": "concat nests rhs",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "concat([1,2],[3,4])",
    "expected": [
      1,
      2,
      3,
      4
    ]
  },
  {
    "case_id": "CHS-SL-015",
    "title": "range half-open then sum",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET range",
    "expected_behavior": "evaluates to 14",
    "mutation_or_shallow_solution_killed": "range includes upper bound",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "sum(range(2, 6))",
    "expected": 14
  },
  {
    "case_id": "CHS-SL-016",
    "title": "contains by value",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET contains",
    "expected_behavior": "evaluates to true",
    "mutation_or_shallow_solution_killed": "contains uses identity only",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "contains([\"a\",\"b\"], \"b\")",
    "expected": true
  },
  {
    "case_id": "CHS-SL-017",
    "title": "keys length for map",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET keys/len(map)",
    "expected_behavior": "evaluates to 3",
    "mutation_or_shallow_solution_killed": "keys returns values or drops names",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "len(keys({a:1,b:2,c:3}))",
    "expected": 3
  },
  {
    "case_id": "CHS-SL-018",
    "title": "values sum for map",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET values/sum",
    "expected_behavior": "evaluates to 12",
    "mutation_or_shallow_solution_killed": "values returns key-value objects",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "sum(values({a:2,b:4,c:6}))",
    "expected": 12
  },
  {
    "case_id": "CHS-SL-019",
    "title": "entries destructuring values",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET entries(map)",
    "expected_behavior": "evaluates to 3",
    "mutation_or_shallow_solution_killed": "entries shape incompatible with for destructuring",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "let mut total = 0; for [k, v] in entries({a:1,b:2}) { total = total + v }; total",
    "expected": 3
  },
  {
    "case_id": "CHS-SL-020",
    "title": "min list overload",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET min(list)",
    "expected_behavior": "evaluates to 3",
    "mutation_or_shallow_solution_killed": "min only supports two arguments",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "min([9,3,7])",
    "expected": 3
  },
  {
    "case_id": "CHS-SL-021",
    "title": "max pair overload",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET max(a,b)",
    "expected_behavior": "evaluates to 9",
    "mutation_or_shallow_solution_killed": "max pair overload absent",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "max(9, 3)",
    "expected": 9
  },
  {
    "case_id": "CHS-SL-022",
    "title": "round floating value",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET round",
    "expected_behavior": "evaluates to 4",
    "mutation_or_shallow_solution_killed": "round truncates instead of rounding",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "round(3.7)",
    "expected": 4
  },
  {
    "case_id": "CHS-SL-023",
    "title": "string char_at and ord",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET char_at/ord",
    "expected_behavior": "evaluates to 65",
    "mutation_or_shallow_solution_killed": "string indexing starts at one",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "ord(char_at(\"Arc\", 0))",
    "expected": 65
  },
  {
    "case_id": "CHS-SL-024",
    "title": "chr ord inverse",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET chr/ord",
    "expected_behavior": "evaluates to \"Z\"",
    "mutation_or_shallow_solution_killed": "character conversion mismatch",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "chr(ord(\"Z\"))",
    "expected": "Z"
  },
  {
    "case_id": "CHS-SL-025",
    "title": "index_of finds first occurrence",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET index_of",
    "expected_behavior": "evaluates to 2",
    "mutation_or_shallow_solution_killed": "index_of returns last occurrence",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "index_of(\"hello\", \"l\")",
    "expected": 2
  },
  {
    "case_id": "CHS-SL-026",
    "title": "to_string numeric conversion",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET to_string",
    "expected_behavior": "evaluates to \"42\"",
    "mutation_or_shallow_solution_killed": "to_string uses debug object format",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "to_string(42)",
    "expected": "42"
  },
  {
    "case_id": "CHS-SL-027",
    "title": "pipeline stdlib chain",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET pipeline with map/filter/sum",
    "expected_behavior": "evaluates to 70",
    "mutation_or_shallow_solution_killed": "pipeline passes arguments in wrong order",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "[1,2,3,4] |> filter(x => x >= 3) |> map(x => x * 10) |> sum()",
    "expected": 70
  },
  {
    "case_id": "CHS-SL-028",
    "title": "nested stdlib callback closure",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET lambdas and lexical scope",
    "expected_behavior": "evaluates to 12",
    "mutation_or_shallow_solution_killed": "stdlib callback loses closure scope",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "let inc = 2; sum(map([1,2,3], x => x + inc))",
    "expected": 12
  },
  {
    "case_id": "CHS-SL-029",
    "title": "partition-like filter complement via all any",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET filter/map/all/any",
    "expected_behavior": "evaluates to true",
    "mutation_or_shallow_solution_killed": "nested callbacks share wrong parameter scope",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "all(filter([1,2,3,4], x => x > 2), y => y >= 3) and any(map([1,2], z => z + 1), q => q == 3)",
    "expected": true
  },
  {
    "case_id": "CHS-SL-030",
    "title": "zip reduce products",
    "module": "stdlib-composition",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET zip/reduce/indexing",
    "expected_behavior": "evaluates to 140",
    "mutation_or_shallow_solution_killed": "nested pair indexing in callbacks fails",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "src": "reduce(zip([1,2,3],[10,20,30]), (acc, pair) => acc + pair[0] * pair[1], 0)",
    "expected": 140
  }
] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);
function run(src: string): any { return interpretWithEnv(parse(lex(src)), createEnv()); }
console.log("Compact stdlib composition tests:");
for (const c of cases) { try { const actual = run(c.src); assert(deepEqual(actual, c.expected), `${c.case_id} expected ${JSON.stringify(c.expected)}, got ${JSON.stringify(actual)}`); pass(); } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); } }
console.log(`  ${passed} passed, ${failed} failed`);
