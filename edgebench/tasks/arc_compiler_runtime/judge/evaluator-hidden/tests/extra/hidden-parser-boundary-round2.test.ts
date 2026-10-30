// Hidden evaluator: parser boundary round 2
// Case count: 40
// Provenance: SPEC_CONFIRMED by public grammar/CHEATSHEET for precedence, postfix, type declarations, comprehensions, destructuring, match, async/tool syntax, and assignment.
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
const cases = [
  {
    "case_id": "HID-PB2-001",
    "title": "pipeline binds after call chain",
    "src": "factory(1)[0].next(2).value |> stringify()",
    "needles": [
      "PipelineExpr",
      "factory",
      "value",
      "stringify"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-002",
    "title": "nested optional and nil fallback",
    "src": "user?.profile?.address?.city ?? \"unknown\"",
    "needles": [
      "BinaryExpr",
      "user",
      "city",
      "unknown"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-003",
    "title": "power precedence under unary",
    "src": "-2 ** 3 + 4 * 5",
    "needles": [
      "BinaryExpr",
      "**"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-004",
    "title": "two generator comprehension with filter",
    "src": "[x + y for x in xs for y in ys if x < y]",
    "needles": [
      "ListComprehension",
      "generators",
      "filter"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-005",
    "title": "object destructuring with rest",
    "src": "let {name, age, ..extra} = user",
    "needles": [
      "LetStmt",
      "extra",
      "name"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-006",
    "title": "array destructuring with rest",
    "src": "let [head, ..tail] = values",
    "needles": [
      "LetStmt",
      "head",
      "tail"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-007",
    "title": "function destructured parameter",
    "src": "fn label({name, age}) { \"{name}:{age}\" }",
    "needles": [
      "FunctionStmt",
      "name",
      "age"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-008",
    "title": "for loop destructured entries",
    "src": "for {key, value} in entries(config) { print(key) }",
    "needles": [
      "ForStmt",
      "key",
      "value"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-009",
    "title": "match object pattern with guard",
    "src": "match response { {ok:true, data} where len(data) > 0 => data, _ => nil }",
    "needles": [
      "MatchExpr",
      "where",
      "data"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-010",
    "title": "type generic result declaration",
    "src": "type Result<T> = Ok(T) | Err(String)",
    "needles": [
      "TypeStmt",
      "Result",
      "Err"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-011",
    "title": "function type alias",
    "src": "type Handler = (Request) -> Response",
    "needles": [
      "TypeStmt",
      "Handler",
      "Response"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-012",
    "title": "constrained age type",
    "src": "type Age = Int where x => x >= 0 and x <= 150",
    "needles": [
      "TypeStmt",
      "Age",
      "where"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-013",
    "title": "regex matching type",
    "src": "type Email = String matching /^[^@]+@[^@]+$/",
    "needles": [
      "TypeStmt",
      "Email",
      "matching"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-014",
    "title": "async await expression",
    "src": "async fn load(id) { await fetch_user(id) }",
    "needles": [
      "FunctionStmt",
      "async",
      "await"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-015",
    "title": "tool call expression",
    "src": "let res = @GET(\"/users/{id}\")",
    "needles": [
      "LetStmt",
      "@GET",
      "users"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-016",
    "title": "try catch with named binding",
    "src": "try { int(\"bad\") } catch err { print(err) }",
    "needles": [
      "Program",
      "catch",
      "err"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-017",
    "title": "do while with nested branch",
    "src": "do { if ready { break }; tick() } while not ready",
    "needles": [
      "Program",
      "while",
      "tick"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-018",
    "title": "do until with assignment",
    "src": "do { x = x + 1 } until x >= 10",
    "needles": [
      "Program",
      "until",
      "x"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-019",
    "title": "string interpolation with nested index",
    "src": "\"value={items[0].name}\"",
    "needles": [
      "StringLiteral",
      "items",
      "name"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-020",
    "title": "map comprehension",
    "src": "{x: x * x for x in range(0, 4)}",
    "needles": [
      "MapComprehension",
      "range"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-021",
    "title": "public arrow function",
    "src": "pub fn score(x) => if x > 0 { x } el { 0 }",
    "needles": [
      "FunctionStmt",
      "pub",
      "score"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-022",
    "title": "return keyword alias",
    "src": "fn choose(xs) { for x in xs { if x > 3 { ret x } }; ret nil }",
    "needles": [
      "FunctionStmt",
      "ret",
      "nil"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-023",
    "title": "module use selected names",
    "src": "use math.{sqrt, pow}",
    "needles": [
      "UseStmt",
      "sqrt",
      "pow"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-024",
    "title": "path import alias",
    "src": "import regex from \"stdlib/regex\"",
    "needles": [
      "ImportStmt",
      "regex",
      "stdlib"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-025",
    "title": "nested arrays and objects",
    "src": "{users:[{name:\"Ada\", roles:[\"admin\"]}], meta:{count:1}}",
    "needles": [
      "ObjectLiteral",
      "users",
      "roles"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-026",
    "title": "pipe lambda call",
    "src": "items |> filter(x => x.active) |> map(x => x.name)",
    "needles": [
      "PipelineExpr",
      "filter",
      "map"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-027",
    "title": "nil propagation expression",
    "src": "config?.database?.primary?",
    "needles": [
      "MemberExpr",
      "database",
      "primary"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-028",
    "title": "match adjacent ranges",
    "src": "match n { 0..9 => \"digit\", 10..99 => \"two\", _ => \"many\" }",
    "needles": [
      "MatchExpr",
      "digit",
      "many"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-029",
    "title": "enum payload type",
    "src": "type Event = Click({x:Int,y:Int}) | Key(String)",
    "needles": [
      "TypeStmt",
      "Click",
      "Key"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-030",
    "title": "record type defaults",
    "src": "type User = {name:String, active:Bool = true}",
    "needles": [
      "TypeStmt",
      "active",
      "Bool"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-031",
    "title": "nested if expression call",
    "src": "render(if ok { value } el { fallback() })",
    "needles": [
      "CallExpr",
      "render",
      "fallback"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-032",
    "title": "index of call result",
    "src": "lookup(users)[0].profile.name",
    "needles": [
      "MemberExpr",
      "lookup",
      "profile"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-033",
    "title": "comments between postfix",
    "src": "user # keep user\n .profile.name",
    "needles": [
      "Program",
      "profile",
      "name"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-034",
    "title": "unicode comparison aliases",
    "src": "x \u2265 0 and x \u2264 10",
    "needles": [
      "BinaryExpr",
      "and"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-035",
    "title": "concat precedence",
    "src": "\"a\" ++ name ++ \"!\"",
    "needles": [
      "BinaryExpr",
      "++"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-036",
    "title": "lambda tuple params",
    "src": "reduce(xs, (acc, x) => acc + x, 0)",
    "needles": [
      "CallExpr",
      "reduce",
      "acc"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-037",
    "title": "rest param with default before",
    "src": "fn join_all(sep = \",\", ...parts) { join(parts, sep) }",
    "needles": [
      "FunctionStmt",
      "parts",
      "sep"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-038",
    "title": "member assignment",
    "src": "user.profile.name = \"Ada\"",
    "needles": [
      "AssignExpr",
      "profile",
      "Ada"
    ],
    "mode": "stmt"
  },
  {
    "case_id": "HID-PB2-039",
    "title": "index assignment",
    "src": "items[0] = items[0] + 1",
    "needles": [
      "AssignExpr",
      "items"
    ],
    "mode": "expr"
  },
  {
    "case_id": "HID-PB2-040",
    "title": "nested comprehension call index",
    "src": "matrix()[row][col] + [x for x in xs][0]",
    "needles": [
      "BinaryExpr",
      "matrix",
      "ListComprehension"
    ],
    "mode": "expr"
  }
] as const;
console.log("Hidden parser boundary round2 tests:");
for (const c of cases) {
  try {
    const ast = parse(lex(c.src));
    const encoded = JSON.stringify(ast);
    assert(Array.isArray(ast.stmts), `${c.case_id} expected Program stmts`);
    for (const n of c.needles) assert(encoded.includes(String(n)), `${c.case_id} AST missing ${n}`);
    pass();
  } catch (e: any) { fail(`${c.case_id} ${c.title}`, e); }
}
console.log(`  ${passed} passed, ${failed} failed`);
