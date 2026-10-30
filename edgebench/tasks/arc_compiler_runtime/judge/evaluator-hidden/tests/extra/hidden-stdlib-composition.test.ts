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

// Hidden evaluator file: stdlib composition
// Case count: 12
// Provenance: SPEC_CONFIRMED from CHEATSHEET string/list/map functions and pipelines.
const cases = [{'case_id': 'HID-SL-001', 'title': 'filter map reduce chain', 'src': 'sum(map(filter([1,2,3,4,5,6], x => x % 2 == 0), x => x * x))', 'expected': 56}, {'case_id': 'HID-SL-002', 'title': 'fold init first', 'src': 'fold([1,2,3,4], 10, (a,b) => a + b)', 'expected': 20}, {'case_id': 'HID-SL-003', 'title': 'find first match', 'src': 'find([1,4,9,16], x => x > 5)', 'expected': 9}, {'case_id': 'HID-SL-004', 'title': 'any all combo', 'src': 'any([1,2,3], x => x == 2) and all([1,2,3], x => x > 0)', 'expected': true}, {'case_id': 'HID-SL-005', 'title': 'flat zip length', 'src': 'len(zip(flat([[1],[2,3]]), ["a","b","c"]))', 'expected': 3}, {'case_id': 'HID-SL-006', 'title': 'take drop reverse', 'src': 'reverse(take(drop([0,1,2,3,4,5], 2), 3))', 'expected': [4, 3, 2]}, {'case_id': 'HID-SL-007', 'title': 'string split upper join', 'src': 'join(map(split("red,blue", ","), x => upper(x)), "|")', 'expected': 'RED|BLUE'}, {'case_id': 'HID-SL-008', 'title': 'replace contains starts ends', 'src': 'contains(replace("hello", "l", "L"), "LL") and starts("hello", "he") and ends("hello", "lo")', 'expected': true}, {'case_id': 'HID-SL-009', 'title': 'slice index char', 'src': 'char_at(slice("abcdef", 1, 4), index_of("bcd", "c"))', 'expected': 'c'}, {'case_id': 'HID-SL-010', 'title': 'object keys values entries', 'src': 'len(keys({a:1,b:2})) + len(values({a:1,b:2})) + len(entries({a:1,b:2}))', 'expected': 6}, {'case_id': 'HID-SL-011', 'title': 'range concat sum', 'src': 'sum(concat(range(0,3), range(3,6)))', 'expected': 15}, {'case_id': 'HID-SL-012', 'title': 'head tail last', 'src': 'head([9,8,7]) + last(tail([9,8,7]))', 'expected': 16}] as const;
const { lex } = requireArc(`${arcRoot}/compiler/src/lexer.js`);
const { parse } = requireArc(`${arcRoot}/compiler/src/parser.js`);
const { createEnv, interpretWithEnv } = requireArc(`${arcRoot}/compiler/src/interpreter.js`);
function runExpr(src: string): any { return interpretWithEnv(parse(lex(src)), createEnv()); }
console.log("Hidden stdlib composition tests:");
for (const c of cases) { try { const actual = runExpr(c.src); assert(deepEqual(actual, c.expected), `${c.case_id} expected ${JSON.stringify(c.expected)}, got ${JSON.stringify(actual)}`); pass(); } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); } }
console.log(`  ${passed} passed, ${failed} failed`);
