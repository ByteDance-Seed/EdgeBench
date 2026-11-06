// Hidden evaluator: adversarial type-system cases (part 2)
// Case count: 40
// Provenance: SPEC_CONFIRMED by public grammar/CHEATSHEET/semantics for lexical scope, mutability, arity, destructuring, and recursion.
import { createRequire } from "module";
import { fileURLToPath } from "url";

export let passed = 0;
export let failed = 0;

const fallbackRoot = fileURLToPath(new URL("../../..", import.meta.url));
const arcRoot = process.env.ARC_TEST_ROOT ?? fallbackRoot;
const requireArc = createRequire(import.meta.url);
function pass() { passed++; }
function fail(name: string, e: any) { failed++; if (failed <= 10) console.error(`  FAIL: ${name} — ${e?.message ?? e}`); }
function assert(cond: boolean, msg: string) { if (!cond) throw new Error(msg); }
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { analyze } = requireArc(`${arcRoot}/compiler/src/semantic.js`);
function errors(source: string): any[] { return analyze(parse(lex(source))).filter((d: any) => d.level === "error"); }
const cases = [
  {
    "case_id": "HID-TY2-M001",
    "title": "immutable reassignment rejected variant 1",
    "src": "let value1 = 1\nif true { value1 = value1 + 1 }\nvalue1",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M002",
    "title": "immutable reassignment rejected variant 2",
    "src": "let value2 = 2\nif true { value2 = value2 + 1 }\nvalue2",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M003",
    "title": "immutable reassignment rejected variant 3",
    "src": "let value3 = 3\nif true { value3 = value3 + 1 }\nvalue3",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M004",
    "title": "immutable reassignment rejected variant 4",
    "src": "let value4 = 4\nif true { value4 = value4 + 1 }\nvalue4",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M005",
    "title": "immutable reassignment rejected variant 5",
    "src": "let value5 = 5\nif true { value5 = value5 + 1 }\nvalue5",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M006",
    "title": "immutable reassignment rejected variant 6",
    "src": "let value6 = 6\nif true { value6 = value6 + 1 }\nvalue6",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M007",
    "title": "immutable reassignment rejected variant 7",
    "src": "let value7 = 7\nif true { value7 = value7 + 1 }\nvalue7",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M008",
    "title": "immutable reassignment rejected variant 8",
    "src": "let value8 = 8\nif true { value8 = value8 + 1 }\nvalue8",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M009",
    "title": "immutable reassignment rejected variant 9",
    "src": "let value9 = 9\nif true { value9 = value9 + 1 }\nvalue9",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M010",
    "title": "immutable reassignment rejected variant 10",
    "src": "let value10 = 10\nif true { value10 = value10 + 1 }\nvalue10",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M011",
    "title": "immutable reassignment rejected variant 11",
    "src": "let value11 = 11\nif true { value11 = value11 + 1 }\nvalue11",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M012",
    "title": "immutable reassignment rejected variant 12",
    "src": "let value12 = 12\nif true { value12 = value12 + 1 }\nvalue12",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M013",
    "title": "immutable reassignment rejected variant 13",
    "src": "let value13 = 13\nif true { value13 = value13 + 1 }\nvalue13",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M014",
    "title": "immutable reassignment rejected variant 14",
    "src": "let value14 = 14\nif true { value14 = value14 + 1 }\nvalue14",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M015",
    "title": "immutable reassignment rejected variant 15",
    "src": "let value15 = 15\nif true { value15 = value15 + 1 }\nvalue15",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M016",
    "title": "immutable reassignment rejected variant 16",
    "src": "let value16 = 16\nif true { value16 = value16 + 1 }\nvalue16",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M017",
    "title": "immutable reassignment rejected variant 17",
    "src": "let value17 = 17\nif true { value17 = value17 + 1 }\nvalue17",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M018",
    "title": "immutable reassignment rejected variant 18",
    "src": "let value18 = 18\nif true { value18 = value18 + 1 }\nvalue18",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M019",
    "title": "immutable reassignment rejected variant 19",
    "src": "let value19 = 19\nif true { value19 = value19 + 1 }\nvalue19",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-M020",
    "title": "immutable reassignment rejected variant 20",
    "src": "let value20 = 20\nif true { value20 = value20 + 1 }\nvalue20",
    "expect": "error",
    "focus": "mutability preservation"
  },
  {
    "case_id": "HID-TY2-A001",
    "title": "user function arity mismatch rejected variant 1",
    "src": "fn f1(a, b) => a\nf1(1, 2, 3)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A002",
    "title": "user function arity mismatch rejected variant 2",
    "src": "fn f2(a, b, c) => a\nf2(1, 2, 3, 4)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A003",
    "title": "user function arity mismatch rejected variant 3",
    "src": "fn f3(a) => a\nf3(1, 2)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A004",
    "title": "user function arity mismatch rejected variant 4",
    "src": "fn f4(a, b) => a\nf4(1, 2, 3)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A005",
    "title": "user function arity mismatch rejected variant 5",
    "src": "fn f5(a, b, c) => a\nf5(1, 2, 3, 4)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A006",
    "title": "user function arity mismatch rejected variant 6",
    "src": "fn f6(a) => a\nf6(1, 2)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A007",
    "title": "user function arity mismatch rejected variant 7",
    "src": "fn f7(a, b) => a\nf7(1, 2, 3)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A008",
    "title": "user function arity mismatch rejected variant 8",
    "src": "fn f8(a, b, c) => a\nf8(1, 2, 3, 4)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A009",
    "title": "user function arity mismatch rejected variant 9",
    "src": "fn f9(a) => a\nf9(1, 2)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A010",
    "title": "user function arity mismatch rejected variant 10",
    "src": "fn f10(a, b) => a\nf10(1, 2, 3)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A011",
    "title": "user function arity mismatch rejected variant 11",
    "src": "fn f11(a, b, c) => a\nf11(1, 2, 3, 4)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A012",
    "title": "user function arity mismatch rejected variant 12",
    "src": "fn f12(a) => a\nf12(1, 2)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A013",
    "title": "user function arity mismatch rejected variant 13",
    "src": "fn f13(a, b) => a\nf13(1, 2, 3)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A014",
    "title": "user function arity mismatch rejected variant 14",
    "src": "fn f14(a, b, c) => a\nf14(1, 2, 3, 4)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A015",
    "title": "user function arity mismatch rejected variant 15",
    "src": "fn f15(a) => a\nf15(1, 2)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A016",
    "title": "user function arity mismatch rejected variant 16",
    "src": "fn f16(a, b) => a\nf16(1, 2, 3)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A017",
    "title": "user function arity mismatch rejected variant 17",
    "src": "fn f17(a, b, c) => a\nf17(1, 2, 3, 4)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A018",
    "title": "user function arity mismatch rejected variant 18",
    "src": "fn f18(a) => a\nf18(1, 2)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A019",
    "title": "user function arity mismatch rejected variant 19",
    "src": "fn f19(a, b) => a\nf19(1, 2, 3)",
    "expect": "error",
    "focus": "function arity contract"
  },
  {
    "case_id": "HID-TY2-A020",
    "title": "user function arity mismatch rejected variant 20",
    "src": "fn f20(a, b, c) => a\nf20(1, 2, 3, 4)",
    "expect": "error",
    "focus": "function arity contract"
  }
] as const;
console.log("Hidden adversarial type-system tests part 2:");
for (const c of cases) {
  try {
    const es = errors(c.src);
    if (c.expect === "ok") assert(es.length === 0, `${c.case_id} expected no semantic errors, got ${JSON.stringify(es)}`);
    else assert(es.length > 0, `${c.case_id} expected at least one semantic error`);
    pass();
  } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); }
}
console.log(`  ${passed} passed, ${failed} failed`);
