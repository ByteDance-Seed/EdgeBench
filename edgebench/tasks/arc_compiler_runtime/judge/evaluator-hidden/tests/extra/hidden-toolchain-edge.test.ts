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

// Hidden evaluator file: toolchain/CLI edge components
// Case count: 8
// Provenance: SPEC_CONFIRMED from CHEATSHEET formatting/lint/security/package-manager surfaces and existing public task docs.
import { mkdtempSync, rmSync, writeFileSync, existsSync, readFileSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";
const cases = [{'case_id': 'HID-TC-001', 'title': 'format do until idempotent', 'kind': 'format', 'src': 'do { x=x+1 } until x>=10'}, {'case_id': 'HID-TC-002', 'title': 'format try catch idempotent', 'kind': 'format', 'src': 'try { int("bad") } catch err { print(err) }'}, {'case_id': 'HID-TC-003', 'title': 'format default rest params', 'kind': 'format', 'src': 'fn collect(head, sep=",", ...tail){ join(tail,sep) }'}, {'case_id': 'HID-TC-004', 'title': 'lint interpolation scoped', 'kind': 'lint-clean', 'src': 'let name = "Ada"\nlet msg = "hi {name}"\nprint(msg)'}, {'case_id': 'HID-TC-005', 'title': 'lint unused var', 'kind': 'lint-unused', 'src': 'let unused_value = 3\nlet used = 4\nprint(used)'}, {'case_id': 'HID-TC-006', 'title': 'security import rejects unknown', 'kind': 'security-import', 'src': 'import danger from "remote/module"'}, {'case_id': 'HID-TC-007', 'title': 'security method allowlist rejects POST', 'kind': 'security-method', 'src': 'POST https://service.invalid'}, {'case_id': 'HID-TC-008', 'title': 'toml dependencies preserve', 'kind': 'toml', 'src': '[package]\nname="demo"\nversion="0.1.0"\n[dependencies]\nmath="1.0.0"\n'}] as const;
const { format } = requireArc(`${arcRoot}/compiler/src/formatter.js`);
const { lint } = requireArc(`${arcRoot}/compiler/src/linter.js`);
const { validateToolCall, validateImport } = requireArc(`${arcRoot}/compiler/src/security.js`);
const { parseArcToml, serializeArcToml } = requireArc(`${arcRoot}/compiler/src/package-manager.js`);
function throws(fn: () => void, pattern?: string): boolean { try { fn(); return false; } catch (e: any) { return pattern ? String(e?.message ?? e).includes(pattern) : true; } }
console.log("Hidden toolchain edge tests:");
for (const c of cases) { try {
  if (c.kind === "format") { const once = format(c.src); const twice = format(once); assert(once === twice, `${c.case_id} formatter not idempotent`); }
  else if (c.kind === "lint-clean") { const diags = lint(c.src); assert(!diags.some((d: any) => String(d.level || d.severity || "").toLowerCase() === "error"), `${c.case_id} expected no severe lint error`); }
  else if (c.kind === "lint-unused") { const diags = lint(c.src); assert(diags.some((d: any) => d.rule === "unused-variable" || String(d.message).includes("unused")), `${c.case_id} expected unused diagnostic`); }
  else if (c.kind === "security-import") { assert(throws(() => validateImport(c.src, { allowedImports: ["math"] }), "allowlist"), `${c.case_id} expected import rejection`); }
  else if (c.kind === "security-method") { assert(throws(() => validateToolCall("POST", "https://service.invalid", { allowedToolMethods: ["GET"] }), "allowlist"), `${c.case_id} expected method rejection`); }
  else if (c.kind === "toml") { const parsed = parseArcToml(c.src); const reparsed = parseArcToml(serializeArcToml(parsed)); assert(reparsed.package?.name === "demo", `${c.case_id} package name lost`); assert(reparsed.dependencies?.math === "1.0.0", `${c.case_id} dependency lost`); }
  else throw new Error(`unknown kind ${c.kind}`);
  pass();
} catch (e: any) { fail(`${c.case_id} ${c.title}`, e); } }
console.log(`  ${passed} passed, ${failed} failed`);
