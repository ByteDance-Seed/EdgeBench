# Arc Stability Guarantees

## Semantic Versioning

Arc follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes to language syntax or semantics
- **MINOR** (0.5.0 → 0.6.0): New features, backward-compatible
- **PATCH** (0.5.0 → 0.5.1): Bug fixes, performance improvements

### Pre-1.0 Policy

While Arc is below 1.0, minor versions **may** include breaking changes. We still aim for stability but reserve the right to improve the language based on feedback. All breaking changes are documented in the [CHANGELOG](../CHANGELOG.md).

### Post-1.0 Policy

After 1.0, breaking changes only occur in major versions with a full deprecation cycle.

---

## Stability Tiers

### 🟢 Stable

These features are covered by semver guarantees. Breaking changes require a major version bump (post-1.0) with a deprecation period.

- Core syntax: `let`, `mut`, `fn`, `match`, `if/else`, `for`, `while`
- Pipeline operator `|>`
- Tool calls `@GET`, `@POST`, `@tool(...)`
- String interpolation `"{expr}"`
- Pattern matching with destructuring
- Module system (`use`, `pub`)
- Type system (annotations, enums, generics)
- Prelude functions (`print`, `len`, `map`, `filter`, `sort`, etc.)
- CLI commands: `run`, `parse`, `compile`, `fmt`, `lint`, `repl`, `version`

### 🟡 Experimental

These features work but their API may change in minor versions. Use at your own risk in production.

- WebAssembly (WAT) code generation
- LSP server protocol details
- Build system (`arc build`)
- Package manager (`arc pkg`)
- Migration tools (JS→Arc, Python→Arc)
- Documentation site generator (`arc docs`)

### 🔴 Internal

Not part of the public API. May change or disappear without notice.

- IR representation details
- Optimizer pass internals
- AST node structure
- Interpreter implementation details

---

## Deprecation Process

Arc uses a **minimum 2 minor versions** deprecation period:

1. **Deprecation announced** (e.g., v0.6.0): Feature marked with `⚠ DEPRECATED` warning at runtime. Migration guide provided.
2. **Warning period** (v0.6.x, v0.7.x): Feature continues to work but emits warnings.
3. **Removal** (v0.8.0 earliest): Feature removed. Code using it will fail with a clear error message pointing to the migration guide.

### What a Deprecation Looks Like

```
⚠ DEPRECATED: 'old_feature' was deprecated in v0.6.0 and will be removed in v0.8.0.
  Migration: Use 'new_feature' instead. See https://arclang.dev/migration/old-to-new
```

### Exceptions

Security vulnerabilities may require immediate removal without a deprecation period. These cases will be clearly documented and announced.

---

## Breaking Change Policy

A breaking change is any modification that causes previously valid Arc code to:
- Fail to parse or compile
- Produce different runtime behavior
- Emit different output

### Before 1.0
- Breaking changes documented in CHANGELOG
- Migration guides provided for significant changes
- At least 1 minor version deprecation warning when feasible

### After 1.0
- Breaking changes only in major versions
- Minimum 2 minor versions deprecation warning
- Automated migration tool (`arc migrate`) when possible
- Clear documentation with before/after examples

---

## Long-Term Support (LTS)

### Plan

Once Arc reaches 1.0:

- **1.x LTS**: Supported for 18 months after 2.0 release
  - Receives security fixes and critical bug fixes
  - No new features
- **Future majors**: Same 18-month LTS window

### Current Status

Arc 0.6.12 is pre-release. No LTS guarantees apply until 1.0.

### Version Support Timeline (Projected)

| Version | Status | Support Until |
|---------|--------|---------------|
| 0.x | Pre-release | Until 1.0 |
| 1.0 | Planned | 18 months after 2.0 |

---

## Reporting Issues

If you encounter unexpected behavior changes between versions:

1. Check the [CHANGELOG](../CHANGELOG.md) for documented changes
2. File an issue at [#/issues](#/issues)
3. Include your Arc version (`arc version`) and a minimal reproduction
