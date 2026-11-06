import { createRequire } from "module";
import { fileURLToPath } from "url";
export let passed = 0;
export let failed = 0;
const arcRoot = process.env.ARC_TEST_ROOT ?? fileURLToPath(new URL("../..", import.meta.url));
const requireArc = createRequire(import.meta.url);
function pass() { passed++; }
function fail(name: string, e: any) { failed++; if (failed <= 4) console.error(`  FAIL: ${name} — ${e?.message ?? e}`); }
function assert(cond: boolean, msg: string) { if (!cond) throw new Error(msg); }
function deepEqual(a: any, b: any): boolean { return JSON.stringify(a) === JSON.stringify(b); }

// Public smoke tests: toolchain basics. Case count: 8.
const cases = [
  ["SMOKE-TOOL-001", "format", "let x=1"],
  ["SMOKE-TOOL-002", "format", "fn add(a,b){a+b}"],
  ["SMOKE-TOOL-003", "lint", "let x = 1\nprint(x)"],
  ["SMOKE-TOOL-004", "security-source", "let x = 1"],
  ["SMOKE-TOOL-005", "toml", "[package]\nname=\"demo\"\nversion=\"0.1.0\"\n"],
  ["SMOKE-TOOL-006", "format", "if true { 1 } else { 0 }"],
  ["SMOKE-TOOL-007", "lint", "fn add(a,b){ a+b }"],
  ["SMOKE-TOOL-008", "security-method", "GET"],
] as const;
const { format } = requireArc(`${arcRoot}/compiler/src/formatter.js`);
const { lint } = requireArc(`${arcRoot}/compiler/src/linter.js`);
const { validateSource, validateToolCall } = requireArc(`${arcRoot}/compiler/src/security.js`);
const { parseArcToml } = requireArc(`${arcRoot}/compiler/src/package-manager.js`);
for (const [id, kind, src] of cases) { try { if (kind === "format") assert(typeof format(src) === "string", `${id} format string`); else if (kind === "lint") assert(Array.isArray(lint(src)), `${id} lint array`); else if (kind === "security-source") validateSource(src, { maxSourceSize: 100 }); else if (kind === "security-method") validateToolCall("GET", "https://service.invalid", { allowedToolMethods: ["GET"] }); else if (kind === "toml") assert(parseArcToml(src).package?.name === "demo", `${id} toml name`); pass(); } catch (e: any) { fail(String(id), e); } }
console.log(`  ${passed} passed, ${failed} failed`);
