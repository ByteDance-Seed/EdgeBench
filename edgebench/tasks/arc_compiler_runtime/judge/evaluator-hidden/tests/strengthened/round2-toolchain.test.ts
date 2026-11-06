// Stage: Toolchain
// Case count: 8
// Provenance: SPEC_CONFIRMED from CHEATSHEET fmt/lint/build/package/security toolchain behavior and existing toolchain tests.
// Included in official scoring: YES. Does not depend on evaluator-only artifacts or network.
import { createRequire } from "module";
import { mkdtempSync, rmSync, existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";

export let passed = 0;
export let failed = 0;

const arcRoot = process.env.ARC_TEST_ROOT ?? new URL("../..", import.meta.url).pathname;
const requireArc = createRequire(import.meta.url);
const { format } = requireArc(`${arcRoot}/compiler/src/formatter.js`);
const { lint } = requireArc(`${arcRoot}/compiler/src/linter.js`);
const { validateSource, validateToolCall, validateImport } = requireArc(`${arcRoot}/compiler/src/security.js`);
const { parseArcToml, serializeArcToml } = requireArc(`${arcRoot}/compiler/src/package-manager.js`);
const { newProject, build } = requireArc(`${arcRoot}/compiler/src/build.js`);

function assert(cond: boolean, msg: string) { if (cond) passed++; else { failed++; console.error(`  FAIL: ${msg}`); } }
function test(name: string, fn: () => void) { try { fn(); } catch (e: any) { failed++; console.error(`  FAIL: ${name} — ${e?.message ?? e}`); } }
function throws(fn: () => void, pattern?: string): boolean { try { fn(); return false; } catch (e: any) { return pattern ? String(e?.message ?? e).includes(pattern) : true; } }

console.log("Round2 Strengthened Toolchain Tests:");

test("formatter is idempotent for simple let", () => {
  const once = format("let x=1");
  assert(format(once) === once, "formatter idempotence");
});

test("formatter preserves leading comment", () => {
  const out = format("# hello\nlet x=1");
  assert(out.includes("# hello") && out.includes("let x = 1"), "comment and let retained");
});

test("linter flags unused but not used variable", () => {
  const unused = lint("let unused_value = 1\nprintln(2)");
  const used = lint("let used_value = 1\nprintln(used_value)");
  assert(unused.some((d: any) => d.rule === "unused-variable") && !used.some((d: any) => d.message.includes("used_value")), "unused diagnostic only when appropriate");
});

test("security source size limit rejects oversized input", () => {
  assert(throws(() => validateSource("abcdef", { maxSourceSize: 5 }), "exceeds maximum size"), "source size guard");
});

test("security method allowlist rejects POST", () => {
  assert(throws(() => validateToolCall("POST", "https://service.invalid", { allowedToolMethods: ["GET"] }), "allowlist"), "method allowlist guard");
});

test("security import allowlist rejects fs", () => {
  assert(throws(() => validateImport("fs", { allowedImports: ["math"] }), "allowlist"), "import allowlist guard");
});

test("parse and serialize TOML preserves package name", () => {
  const parsed = parseArcToml('[package]\nname = "demo"\nversion = "0.1.0"\n');
  const reparsed = parseArcToml(serializeArcToml(parsed));
  assert(reparsed.package.name === "demo", "package name roundtrip");
});

test("new project can build JS output", () => {
  const dir = mkdtempSync(join(tmpdir(), "arc-round2-build-"));
  try {
    newProject("demo", dir);
    const projectDir = join(dir, "demo");
    writeFileSync(join(projectDir, "src", "main.arc"), "let x = 42\n");
    build({ target: "js", dir: projectDir });
    assert(existsSync(join(projectDir, "dist", "demo.js")) && readFileSync(join(projectDir, "dist", "demo.js"), "utf8").length > 0, "build output exists");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

console.log(`  ${passed} passed, ${failed} failed`);
