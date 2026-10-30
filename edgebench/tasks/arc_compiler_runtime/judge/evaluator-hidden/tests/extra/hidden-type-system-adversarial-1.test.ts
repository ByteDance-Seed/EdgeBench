// Hidden evaluator: adversarial type-system cases (part 1)
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
    "case_id": "HID-TY2-U001",
    "title": "block scoped binding does not leak variant 1",
    "src": "if true { let hidden1 = 1 }\nhidden1",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U002",
    "title": "block scoped binding does not leak variant 2",
    "src": "if true { let hidden2 = 2 }\nhidden2",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U003",
    "title": "block scoped binding does not leak variant 3",
    "src": "if true { let hidden3 = 3 }\nhidden3",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U004",
    "title": "block scoped binding does not leak variant 4",
    "src": "if true { let hidden4 = 4 }\nhidden4",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U005",
    "title": "block scoped binding does not leak variant 5",
    "src": "if true { let hidden5 = 5 }\nhidden5",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U006",
    "title": "block scoped binding does not leak variant 6",
    "src": "if true { let hidden6 = 6 }\nhidden6",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U007",
    "title": "block scoped binding does not leak variant 7",
    "src": "if true { let hidden7 = 7 }\nhidden7",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U008",
    "title": "block scoped binding does not leak variant 8",
    "src": "if true { let hidden8 = 8 }\nhidden8",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U009",
    "title": "block scoped binding does not leak variant 9",
    "src": "if true { let hidden9 = 9 }\nhidden9",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U010",
    "title": "block scoped binding does not leak variant 10",
    "src": "if true { let hidden10 = 10 }\nhidden10",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U011",
    "title": "block scoped binding does not leak variant 11",
    "src": "if true { let hidden11 = 11 }\nhidden11",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U012",
    "title": "block scoped binding does not leak variant 12",
    "src": "if true { let hidden12 = 12 }\nhidden12",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U013",
    "title": "block scoped binding does not leak variant 13",
    "src": "if true { let hidden13 = 13 }\nhidden13",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U014",
    "title": "block scoped binding does not leak variant 14",
    "src": "if true { let hidden14 = 14 }\nhidden14",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U015",
    "title": "block scoped binding does not leak variant 15",
    "src": "if true { let hidden15 = 15 }\nhidden15",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U016",
    "title": "block scoped binding does not leak variant 16",
    "src": "if true { let hidden16 = 16 }\nhidden16",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U017",
    "title": "block scoped binding does not leak variant 17",
    "src": "if true { let hidden17 = 17 }\nhidden17",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U018",
    "title": "block scoped binding does not leak variant 18",
    "src": "if true { let hidden18 = 18 }\nhidden18",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U019",
    "title": "block scoped binding does not leak variant 19",
    "src": "if true { let hidden19 = 19 }\nhidden19",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-U020",
    "title": "block scoped binding does not leak variant 20",
    "src": "if true { let hidden20 = 20 }\nhidden20",
    "expect": "error",
    "focus": "block lexical scope"
  },
  {
    "case_id": "HID-TY2-L001",
    "title": "loop scoped binding does not leak variant 1",
    "src": "for item1 in [1,2,3] { let doubled1 = item1 * 2 }\ndoubled1",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L002",
    "title": "loop scoped binding does not leak variant 2",
    "src": "for item2 in [1,2,3] { let doubled2 = item2 * 2 }\ndoubled2",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L003",
    "title": "loop scoped binding does not leak variant 3",
    "src": "for item3 in [1,2,3] { let doubled3 = item3 * 2 }\ndoubled3",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L004",
    "title": "loop scoped binding does not leak variant 4",
    "src": "for item4 in [1,2,3] { let doubled4 = item4 * 2 }\ndoubled4",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L005",
    "title": "loop scoped binding does not leak variant 5",
    "src": "for item5 in [1,2,3] { let doubled5 = item5 * 2 }\ndoubled5",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L006",
    "title": "loop scoped binding does not leak variant 6",
    "src": "for item6 in [1,2,3] { let doubled6 = item6 * 2 }\ndoubled6",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L007",
    "title": "loop scoped binding does not leak variant 7",
    "src": "for item7 in [1,2,3] { let doubled7 = item7 * 2 }\ndoubled7",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L008",
    "title": "loop scoped binding does not leak variant 8",
    "src": "for item8 in [1,2,3] { let doubled8 = item8 * 2 }\ndoubled8",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L009",
    "title": "loop scoped binding does not leak variant 9",
    "src": "for item9 in [1,2,3] { let doubled9 = item9 * 2 }\ndoubled9",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L010",
    "title": "loop scoped binding does not leak variant 10",
    "src": "for item10 in [1,2,3] { let doubled10 = item10 * 2 }\ndoubled10",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L011",
    "title": "loop scoped binding does not leak variant 11",
    "src": "for item11 in [1,2,3] { let doubled11 = item11 * 2 }\ndoubled11",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L012",
    "title": "loop scoped binding does not leak variant 12",
    "src": "for item12 in [1,2,3] { let doubled12 = item12 * 2 }\ndoubled12",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L013",
    "title": "loop scoped binding does not leak variant 13",
    "src": "for item13 in [1,2,3] { let doubled13 = item13 * 2 }\ndoubled13",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L014",
    "title": "loop scoped binding does not leak variant 14",
    "src": "for item14 in [1,2,3] { let doubled14 = item14 * 2 }\ndoubled14",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L015",
    "title": "loop scoped binding does not leak variant 15",
    "src": "for item15 in [1,2,3] { let doubled15 = item15 * 2 }\ndoubled15",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L016",
    "title": "loop scoped binding does not leak variant 16",
    "src": "for item16 in [1,2,3] { let doubled16 = item16 * 2 }\ndoubled16",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L017",
    "title": "loop scoped binding does not leak variant 17",
    "src": "for item17 in [1,2,3] { let doubled17 = item17 * 2 }\ndoubled17",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L018",
    "title": "loop scoped binding does not leak variant 18",
    "src": "for item18 in [1,2,3] { let doubled18 = item18 * 2 }\ndoubled18",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L019",
    "title": "loop scoped binding does not leak variant 19",
    "src": "for item19 in [1,2,3] { let doubled19 = item19 * 2 }\ndoubled19",
    "expect": "error",
    "focus": "loop lexical scope"
  },
  {
    "case_id": "HID-TY2-L020",
    "title": "loop scoped binding does not leak variant 20",
    "src": "for item20 in [1,2,3] { let doubled20 = item20 * 2 }\ndoubled20",
    "expect": "error",
    "focus": "loop lexical scope"
  }
] as const;
console.log("Hidden adversarial type-system tests part 1:");
for (const c of cases) {
  try {
    const es = errors(c.src);
    if (c.expect === "ok") assert(es.length === 0, `${c.case_id} expected no semantic errors, got ${JSON.stringify(es)}`);
    else assert(es.length > 0, `${c.case_id} expected at least one semantic error`);
    pass();
  } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); }
}
console.log(`  ${passed} passed, ${failed} failed`);
