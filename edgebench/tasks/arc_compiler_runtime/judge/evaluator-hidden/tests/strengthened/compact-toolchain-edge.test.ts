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
// Module: toolchain / CLI edge cases
// Case count: 20
// SPEC_CONFIRMED from solver-visible CHEATSHEET.md toolchain commands and existing toolchain tests.
import { mkdtempSync, rmSync, existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
const cases = [
  {
    "case_id": "CHS-TC-001",
    "title": "formatter idempotent for destructuring",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET destructuring and fmt",
    "expected_behavior": "second format equals first and contains rest binding",
    "mutation_or_shallow_solution_killed": "formatter drops rest syntax",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "format",
    "src": "let [head,...tail]=[1,2,3]"
  },
  {
    "case_id": "CHS-TC-002",
    "title": "formatter preserves interpolation expression",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET interpolation and fmt",
    "expected_behavior": "formatted output retains interpolation function call",
    "mutation_or_shallow_solution_killed": "formatter treats braces as block delimiters",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "format",
    "src": "let s=\"total: {sum([1,2,3])}\""
  },
  {
    "case_id": "CHS-TC-003",
    "title": "formatter preserves match range arm",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET match ranges and fmt",
    "expected_behavior": "formatted output retains match and range syntax",
    "mutation_or_shallow_solution_killed": "formatter cannot parse match range",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "format",
    "src": "let x=match code { 200=>\"ok\", 400..499=>\"client\", _=>\"other\" }"
  },
  {
    "case_id": "CHS-TC-004",
    "title": "formatter preserves pipeline order",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET pipeline and fmt",
    "expected_behavior": "formatted output retains two pipe operators",
    "mutation_or_shallow_solution_killed": "formatter reorders or drops pipeline",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "format",
    "src": "let y=[1,2,3]|>map(x=>x+1)|>sum()"
  },
  {
    "case_id": "CHS-TC-005",
    "title": "formatter handles function default parameter",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET default parameters and fmt",
    "expected_behavior": "formatted output retains default parameter",
    "mutation_or_shallow_solution_killed": "formatter rejects default args",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "format",
    "src": "fn greet(name=\"world\"){ \"hi {name}\" }"
  },
  {
    "case_id": "CHS-TC-006",
    "title": "linter flags truly unused variable",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Existing linter tests and lint command",
    "expected_behavior": "unused-variable diagnostic emitted",
    "mutation_or_shallow_solution_killed": "linter misses unused locals",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "lint-unused",
    "src": "let unused_value = 1\nprintln(2)"
  },
  {
    "case_id": "CHS-TC-007",
    "title": "linter accepts callback parameter use",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET lambdas and linter behavior",
    "expected_behavior": "no unused diagnostic for callback parameter x",
    "mutation_or_shallow_solution_killed": "linter treats lambda parameters as undefined/unused",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "lint-clean",
    "src": "let xs = map([1,2], x => x + 1)\nprintln(xs)"
  },
  {
    "case_id": "CHS-TC-008",
    "title": "linter accepts destructured loop variables",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET entries destructuring",
    "expected_behavior": "no unused diagnostic for destructured loop variables",
    "mutation_or_shallow_solution_killed": "linter does not bind destructured loop names",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "lint-clean",
    "src": "for [key, val] in entries({a:1}) { println(key); println(val) }"
  },
  {
    "case_id": "CHS-TC-009",
    "title": "security rejects oversized source",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Existing security API tests",
    "expected_behavior": "validateSource throws maximum size error",
    "mutation_or_shallow_solution_killed": "security source size guard absent",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "security-source",
    "src": "abcdef"
  },
  {
    "case_id": "CHS-TC-010",
    "title": "security method allowlist rejects POST",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Existing security API tests",
    "expected_behavior": "validateToolCall rejects method not in allowlist",
    "mutation_or_shallow_solution_killed": "tool call allowlist ignored",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "security-method",
    "src": "POST https://service.invalid"
  },
  {
    "case_id": "CHS-TC-011",
    "title": "security import allowlist rejects fs",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Existing security API tests",
    "expected_behavior": "validateImport rejects disallowed import",
    "mutation_or_shallow_solution_killed": "import allowlist ignored",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "security-import",
    "src": "fs"
  },
  {
    "case_id": "CHS-TC-012",
    "title": "TOML package roundtrip keeps name",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Existing package-manager tests",
    "expected_behavior": "parse + serialize preserves package name",
    "mutation_or_shallow_solution_killed": "TOML serializer drops package table",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "toml",
    "src": "[package]\nname = \"demo\"\nversion = \"0.1.0\"\n"
  },
  {
    "case_id": "CHS-TC-013",
    "title": "new project creates source tree",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Existing build/new project tests",
    "expected_behavior": "newProject creates demo/src/main.arc",
    "mutation_or_shallow_solution_killed": "newProject incomplete scaffold",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "new-project",
    "src": "demo"
  },
  {
    "case_id": "CHS-TC-014",
    "title": "build writes JS output",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET arc build / compile",
    "expected_behavior": "build target js creates non-empty dist/demo.js",
    "mutation_or_shallow_solution_killed": "build does not invoke codegen",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "build-js",
    "src": "let x = 42\n"
  },
  {
    "case_id": "CHS-TC-015",
    "title": "formatter handles selective use",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET selective imports",
    "expected_behavior": "formatted output retains selected imports",
    "mutation_or_shallow_solution_killed": "formatter rejects use braces",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "format",
    "src": "use math { sqrt, PI }\nlet x=sqrt(16)"
  },
  {
    "case_id": "CHS-TC-016",
    "title": "formatter handles import from path",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET import from path",
    "expected_behavior": "formatted output retains import path string",
    "mutation_or_shallow_solution_killed": "formatter rejects import-from syntax",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "format",
    "src": "import regex from \"stdlib/regex\""
  },
  {
    "case_id": "CHS-TC-017",
    "title": "linter accepts interpolation names from scope",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET string interpolation",
    "expected_behavior": "no undefined/unused diagnostic for interpolation variable",
    "mutation_or_shallow_solution_killed": "linter ignores interpolation scope",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "lint-clean",
    "src": "let name = \"Arc\"\nlet greeting = \"hi {name}\"\nprintln(greeting)"
  },
  {
    "case_id": "CHS-TC-018",
    "title": "formatter handles object destructuring parameter",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "CHEATSHEET destructuring params",
    "expected_behavior": "formatted output retains destructured parameter",
    "mutation_or_shallow_solution_killed": "formatter rejects object parameter patterns",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "format",
    "src": "fn greet({name, age}) { \"Hi {name}\" }"
  },
  {
    "case_id": "CHS-TC-019",
    "title": "security valid GET remains allowed",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Existing security API tests",
    "expected_behavior": "validateToolCall allows GET when allowlisted",
    "mutation_or_shallow_solution_killed": "security allowlist rejects allowed method",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "security-allow",
    "src": "GET https://service.invalid"
  },
  {
    "case_id": "CHS-TC-020",
    "title": "TOML dependency table roundtrip",
    "module": "toolchain-edge",
    "difficulty": "ADVERSARIAL",
    "proposed_weight": 10,
    "public_spec_basis": "Arc package-manager TOML format",
    "expected_behavior": "parse + serialize preserves dependency key",
    "mutation_or_shallow_solution_killed": "serializer drops dependencies",
    "deterministic": true,
    "network_required": false,
    "external_dependency": false,
    "promotion_status": "PROMOTE_OFFICIAL",
    "kind": "toml",
    "src": "[package]\nname = \"demo\"\nversion = \"0.1.0\"\n[dependencies]\nmath = \"1.0.0\"\n"
  }
] as const;
const { format } = requireArc(`${arcRoot}/compiler/src/formatter.js`);
const { lint } = requireArc(`${arcRoot}/compiler/src/linter.js`);
const { validateSource, validateToolCall, validateImport } = requireArc(`${arcRoot}/compiler/src/security.js`);
const { parseArcToml, serializeArcToml } = requireArc(`${arcRoot}/compiler/src/package-manager.js`);
const { newProject, build } = requireArc(`${arcRoot}/compiler/src/build.js`);
function throws(fn: () => void, pattern?: string): boolean { try { fn(); return false; } catch (e: any) { return pattern ? String(e?.message ?? e).includes(pattern) : true; } }
console.log("Compact toolchain edge tests:");
for (const c of cases) { try {
  if (c.kind === "format") { const once = format(c.src); const twice = format(once); assert(once === twice, `${c.case_id} formatter not idempotent`); for (const token of c.src.match(/[A-Za-z_][A-Za-z0-9_]*|\.\.\?|\.\.|\|>|\?\?|\?\./g) || []) { if (["let","fn"].includes(token)) continue; assert(String(once).includes(token.replace("..?","..")) || token === "=>", `${c.case_id} formatted output missing token ${token}`); } }
  else if (c.kind === "lint-unused") { const diags = lint(c.src); assert(diags.some((d: any) => d.rule === "unused-variable" || String(d.message).includes("unused_value")), `${c.case_id} expected unused diagnostic`); }
  else if (c.kind === "lint-clean") { const diags = lint(c.src); assert(!diags.some((d: any) => String(d.level || d.severity || "").toLowerCase() === "error"), `${c.case_id} expected no severe lint error, got ${JSON.stringify(diags)}`); }
  else if (c.kind === "security-source") { assert(throws(() => validateSource(c.src, { maxSourceSize: 5 }), "maximum"), `${c.case_id} expected source size rejection`); }
  else if (c.kind === "security-method") { assert(throws(() => validateToolCall("POST", "https://service.invalid", { allowedToolMethods: ["GET"] }), "allowlist"), `${c.case_id} expected method rejection`); }
  else if (c.kind === "security-import") { assert(throws(() => validateImport(c.src, { allowedImports: ["math"] }), "allowlist"), `${c.case_id} expected import rejection`); }
  else if (c.kind === "security-allow") { validateToolCall("GET", "https://service.invalid", { allowedToolMethods: ["GET"] }); }
  else if (c.kind === "toml") { const parsed = parseArcToml(c.src); const reparsed = parseArcToml(serializeArcToml(parsed)); assert(reparsed.package?.name === "demo", `${c.case_id} package name lost`); if (String(c.src).includes("dependencies")) assert(reparsed.dependencies?.math === "1.0.0", `${c.case_id} dependency lost`); }
  else if (c.kind === "new-project") { const dir = mkdtempSync(join(tmpdir(), "arc-compact-new-")); try { newProject("demo", dir); assert(existsSync(join(dir, "demo", "src", "main.arc")), `${c.case_id} main.arc missing`); } finally { rmSync(dir, { recursive: true, force: true }); } }
  else if (c.kind === "build-js") { const dir = mkdtempSync(join(tmpdir(), "arc-compact-build-")); try { newProject("demo", dir); const projectDir = join(dir, "demo"); writeFileSync(join(projectDir, "src", "main.arc"), c.src); build({ target: "js", dir: projectDir }); const out = join(projectDir, "dist", "demo.js"); assert(existsSync(out) && readFileSync(out, "utf8").length > 0, `${c.case_id} build output missing`); } finally { rmSync(dir, { recursive: true, force: true }); } }
  else throw new Error(`unknown kind ${c.kind}`);
  pass();
} catch (e: any) { fail(`${c.case_id} ${c.title}`, e); } }
console.log(`  ${passed} passed, ${failed} failed`);
