// Hidden evaluator: adversarial type-system cases (part 3)
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
    "case_id": "HID-TY2-VS001",
    "title": "nested lexical shadowing accepted variant 1",
    "src": "let x = 1\nfn outer1() { let x = 2; fn inner1() => x + 1; inner1() }\nouter1() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS002",
    "title": "nested lexical shadowing accepted variant 2",
    "src": "let x = 2\nfn outer2() { let x = 3; fn inner2() => x + 1; inner2() }\nouter2() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS003",
    "title": "nested lexical shadowing accepted variant 3",
    "src": "let x = 3\nfn outer3() { let x = 4; fn inner3() => x + 1; inner3() }\nouter3() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS004",
    "title": "nested lexical shadowing accepted variant 4",
    "src": "let x = 4\nfn outer4() { let x = 5; fn inner4() => x + 1; inner4() }\nouter4() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS005",
    "title": "nested lexical shadowing accepted variant 5",
    "src": "let x = 5\nfn outer5() { let x = 6; fn inner5() => x + 1; inner5() }\nouter5() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS006",
    "title": "nested lexical shadowing accepted variant 6",
    "src": "let x = 6\nfn outer6() { let x = 7; fn inner6() => x + 1; inner6() }\nouter6() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS007",
    "title": "nested lexical shadowing accepted variant 7",
    "src": "let x = 7\nfn outer7() { let x = 8; fn inner7() => x + 1; inner7() }\nouter7() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS008",
    "title": "nested lexical shadowing accepted variant 8",
    "src": "let x = 8\nfn outer8() { let x = 9; fn inner8() => x + 1; inner8() }\nouter8() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS009",
    "title": "nested lexical shadowing accepted variant 9",
    "src": "let x = 9\nfn outer9() { let x = 10; fn inner9() => x + 1; inner9() }\nouter9() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS010",
    "title": "nested lexical shadowing accepted variant 10",
    "src": "let x = 10\nfn outer10() { let x = 11; fn inner10() => x + 1; inner10() }\nouter10() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS011",
    "title": "nested lexical shadowing accepted variant 11",
    "src": "let x = 11\nfn outer11() { let x = 12; fn inner11() => x + 1; inner11() }\nouter11() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS012",
    "title": "nested lexical shadowing accepted variant 12",
    "src": "let x = 12\nfn outer12() { let x = 13; fn inner12() => x + 1; inner12() }\nouter12() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS013",
    "title": "nested lexical shadowing accepted variant 13",
    "src": "let x = 13\nfn outer13() { let x = 14; fn inner13() => x + 1; inner13() }\nouter13() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS014",
    "title": "nested lexical shadowing accepted variant 14",
    "src": "let x = 14\nfn outer14() { let x = 15; fn inner14() => x + 1; inner14() }\nouter14() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS015",
    "title": "nested lexical shadowing accepted variant 15",
    "src": "let x = 15\nfn outer15() { let x = 16; fn inner15() => x + 1; inner15() }\nouter15() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS016",
    "title": "nested lexical shadowing accepted variant 16",
    "src": "let x = 16\nfn outer16() { let x = 17; fn inner16() => x + 1; inner16() }\nouter16() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS017",
    "title": "nested lexical shadowing accepted variant 17",
    "src": "let x = 17\nfn outer17() { let x = 18; fn inner17() => x + 1; inner17() }\nouter17() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS018",
    "title": "nested lexical shadowing accepted variant 18",
    "src": "let x = 18\nfn outer18() { let x = 19; fn inner18() => x + 1; inner18() }\nouter18() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS019",
    "title": "nested lexical shadowing accepted variant 19",
    "src": "let x = 19\nfn outer19() { let x = 20; fn inner19() => x + 1; inner19() }\nouter19() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VS020",
    "title": "nested lexical shadowing accepted variant 20",
    "src": "let x = 20\nfn outer20() { let x = 21; fn inner20() => x + 1; inner20() }\nouter20() + x",
    "expect": "ok",
    "focus": "lexical closure scope"
  },
  {
    "case_id": "HID-TY2-VD001",
    "title": "destructuring introduces visible names variant 1",
    "src": "let [first1, second1, ..rest1] = [1, 2, 3]\nfirst1 + second1",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VD002",
    "title": "destructuring introduces visible names variant 2",
    "src": "let [first2, second2, ..rest2] = [2, 3, 4]\nfirst2 + second2",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VD003",
    "title": "destructuring introduces visible names variant 3",
    "src": "let [first3, second3, ..rest3] = [3, 4, 5]\nfirst3 + second3",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VD004",
    "title": "destructuring introduces visible names variant 4",
    "src": "let [first4, second4, ..rest4] = [4, 5, 6]\nfirst4 + second4",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VD005",
    "title": "destructuring introduces visible names variant 5",
    "src": "let [first5, second5, ..rest5] = [5, 6, 7]\nfirst5 + second5",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VD006",
    "title": "destructuring introduces visible names variant 6",
    "src": "let [first6, second6, ..rest6] = [6, 7, 8]\nfirst6 + second6",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VD007",
    "title": "destructuring introduces visible names variant 7",
    "src": "let [first7, second7, ..rest7] = [7, 8, 9]\nfirst7 + second7",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VD008",
    "title": "destructuring introduces visible names variant 8",
    "src": "let [first8, second8, ..rest8] = [8, 9, 10]\nfirst8 + second8",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VD009",
    "title": "destructuring introduces visible names variant 9",
    "src": "let [first9, second9, ..rest9] = [9, 10, 11]\nfirst9 + second9",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VD010",
    "title": "destructuring introduces visible names variant 10",
    "src": "let [first10, second10, ..rest10] = [10, 11, 12]\nfirst10 + second10",
    "expect": "ok",
    "focus": "array destructuring names"
  },
  {
    "case_id": "HID-TY2-VR001",
    "title": "mutual recursion accepted variant 1",
    "src": "fn even1(n) => if n == 0 { true } el { odd1(n - 1) }\nfn odd1(n) => if n == 0 { false } el { even1(n - 1) }\neven1(2)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  },
  {
    "case_id": "HID-TY2-VR002",
    "title": "mutual recursion accepted variant 2",
    "src": "fn even2(n) => if n == 0 { true } el { odd2(n - 1) }\nfn odd2(n) => if n == 0 { false } el { even2(n - 1) }\neven2(4)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  },
  {
    "case_id": "HID-TY2-VR003",
    "title": "mutual recursion accepted variant 3",
    "src": "fn even3(n) => if n == 0 { true } el { odd3(n - 1) }\nfn odd3(n) => if n == 0 { false } el { even3(n - 1) }\neven3(6)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  },
  {
    "case_id": "HID-TY2-VR004",
    "title": "mutual recursion accepted variant 4",
    "src": "fn even4(n) => if n == 0 { true } el { odd4(n - 1) }\nfn odd4(n) => if n == 0 { false } el { even4(n - 1) }\neven4(8)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  },
  {
    "case_id": "HID-TY2-VR005",
    "title": "mutual recursion accepted variant 5",
    "src": "fn even5(n) => if n == 0 { true } el { odd5(n - 1) }\nfn odd5(n) => if n == 0 { false } el { even5(n - 1) }\neven5(10)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  },
  {
    "case_id": "HID-TY2-VR006",
    "title": "mutual recursion accepted variant 6",
    "src": "fn even6(n) => if n == 0 { true } el { odd6(n - 1) }\nfn odd6(n) => if n == 0 { false } el { even6(n - 1) }\neven6(12)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  },
  {
    "case_id": "HID-TY2-VR007",
    "title": "mutual recursion accepted variant 7",
    "src": "fn even7(n) => if n == 0 { true } el { odd7(n - 1) }\nfn odd7(n) => if n == 0 { false } el { even7(n - 1) }\neven7(14)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  },
  {
    "case_id": "HID-TY2-VR008",
    "title": "mutual recursion accepted variant 8",
    "src": "fn even8(n) => if n == 0 { true } el { odd8(n - 1) }\nfn odd8(n) => if n == 0 { false } el { even8(n - 1) }\neven8(16)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  },
  {
    "case_id": "HID-TY2-VR009",
    "title": "mutual recursion accepted variant 9",
    "src": "fn even9(n) => if n == 0 { true } el { odd9(n - 1) }\nfn odd9(n) => if n == 0 { false } el { even9(n - 1) }\neven9(18)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  },
  {
    "case_id": "HID-TY2-VR010",
    "title": "mutual recursion accepted variant 10",
    "src": "fn even10(n) => if n == 0 { true } el { odd10(n - 1) }\nfn odd10(n) => if n == 0 { false } el { even10(n - 1) }\neven10(20)",
    "expect": "ok",
    "focus": "mutual recursion hoisting"
  }
] as const;
console.log("Hidden adversarial type-system tests part 3:");
for (const c of cases) {
  try {
    const es = errors(c.src);
    if (c.expect === "ok") assert(es.length === 0, `${c.case_id} expected no semantic errors, got ${JSON.stringify(es)}`);
    else assert(es.length > 0, `${c.case_id} expected at least one semantic error`);
    pass();
  } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); }
}
console.log(`  ${passed} passed, ${failed} failed`);
