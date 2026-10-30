# Arc Compiler Architecture

## Overview

The Arc compiler transforms Arc source code into executable output through a multi-stage pipeline. Each stage is designed for correctness, performance, and extensibility.

```
Source → Lexer → Parser → AST → Semantic Analysis → IR → Optimization → Codegen → Output
```

---

## Pipeline Stages

### 1. Lexer (Tokenization)

**Input:** Raw source text
**Output:** Token stream

Converts source characters into typed tokens. Arc's small keyword set (24 reserved words) makes lexing fast.

```
Token Types:
  Keywords:    fn, let, mut, type, use, pub, match, if, el, for, in, ...
  Literals:    Int, Float, String (with interpolation segments), Bool, Nil
  Operators:   +, -, *, /, %, **, ==, !=, <, >, <=, >=, |>, =>, ->, ?, ..
  Delimiters:  (, ), {, }, [, ], ,, :
  Special:     @, #
  Identifiers: user-defined names
```

**Design decisions:**
- String interpolation `"{expr}"` is lexed as alternating string/expression segments — avoids reparsing.
- `@` is a dedicated token for tool calls — single lookahead determines if it's `@GET`/`@POST` or `@ident(...)`.
- `#` comments are stripped at lex time.

### 2. Parser

**Input:** Token stream
**Output:** Concrete Syntax Tree (CST) / AST

Recursive descent parser (Pratt parsing for expressions). Arc's grammar is LL(1) with minor exceptions (resolved by single-token lookahead).

**Key parsing challenges:**
- **Lambda vs grouping:** `(x) => ...` vs `(expr)` — resolved by lookahead for `=>`.
- **Record literal vs block:** `{ a: 1 }` vs `{ stmt; stmt }` — resolved by checking for `:` after first ident.
- **Tool calls:** `@GET "url"` vs `@ident(args)` — resolved by checking if identifier is an HTTP method.

**Error recovery:** The parser uses synchronization points (`}`, newlines at statement boundaries) to recover from errors and report multiple diagnostics per parse.

### 3. AST (Abstract Syntax Tree)

Core node types:

```
Program          = [Statement]
Statement        = Use | TypeDef | FnDef | Let | ExprStmt | For | Do
Expression       = Literal | Ident | BinOp | UnaryOp | Call | Member
                 | Index | Pipeline | If | Match | Lambda | List | Map
                 | StringInterp | ToolCall | Propagate | NilCoalesce
Pattern          = Wildcard | LitPat | BindPat | VariantPat | RecordPat
                 | ListPat | OrPat | TypedPat
TypeExpr         = Named | Record | Enum | Union | Constrained | FnType
```

All AST nodes carry source spans for error reporting.

### 4. Semantic Analysis

**Input:** Raw AST
**Output:** Annotated AST (types resolved, scopes linked)

Phases:
1. **Name resolution** — Link identifiers to definitions, resolve imports.
2. **Type inference** — Hindley-Milner-style with extensions for semantic types (`where`, `matching`).
3. **Type checking** — Verify constraints, check exhaustive pattern matches.
4. **Borrow/lifecycle analysis** — (Phase 2+) For memory safety if targeting native.
5. **Diagnostic emission** — Errors and warnings with source spans.

**Semantic type validation:**
- `String matching /regex/` → compiled regex stored in type metadata; validated at construction.
- `Int where pred` → predicate compiled to runtime check at value construction boundaries.
- Enum exhaustiveness checking for `match` expressions.

### 5. Intermediate Representation (IR)

Three-address code SSA (Static Single Assignment) form:

```
%1 = load "api/users/{id}"
%2 = call @GET %1
%3 = field %2 "name"
%4 = call print %3
```

**Why SSA:**
- Enables powerful optimizations (constant propagation, dead code elimination, common subexpression elimination).
- Well-understood, proven approach (LLVM, GCC).
- Clean mapping to both bytecode and native backends.

### 6. Optimization Passes

Ordered from highest to lowest impact for agent workloads:

| Pass | Description | Token Efficiency Impact |
|------|-------------|----------------------|
| **Dead code elimination** | Remove unreachable/unused code | Reduces output size |
| **Constant folding** | Evaluate compile-time expressions | Faster execution |
| **Inlining** | Inline small functions (< 5 IR instructions) | Reduce call overhead |
| **String interning** | Deduplicate string literals | Memory savings |
| **Tool call batching** | Merge sequential independent `@` calls into parallel | Latency reduction |
| **Tail call optimization** | Convert tail recursion to loops | Stack safety |
| **Common subexpression** | Reuse computed values | Fewer instructions |
| **Pipeline fusion** | Merge `|>` chains into single pass | Avoid intermediate allocations |

**Novel: Tool call batching** — The optimizer detects independent `@` calls and automatically parallelizes them:
```arc
# Source
let a = @GET "api/x"
let b = @GET "api/y"

# Optimized IR — executes in parallel
[a, b] = parallel_fetch ["api/x", "api/y"]
```

### 7. Code Generation

#### Recommended Target: **WebAssembly (WASM) + JavaScript**

**Rationale:**

| Factor | WASM | LLVM Native | JVM | Custom VM |
|--------|------|-------------|-----|-----------|
| Portability | ✅ Runs everywhere | ❌ Per-platform | ⚠️ JVM required | ❌ Custom runtime |
| Agent deployment | ✅ Browser + server | ⚠️ Server only | ⚠️ Server only | ❌ Custom runtime |
| Ecosystem access | ✅ JS interop | ⚠️ C FFI | ✅ Java interop | ❌ None |
| Startup speed | ✅ Fast | ✅ Fast | ❌ Slow | ✅ Fast |
| Development effort | ⚠️ Medium | ❌ High | ⚠️ Medium | ⚠️ Medium |
| Async I/O | ✅ Via JS runtime | ⚠️ OS-specific | ✅ Via JVM | ⚠️ Must build |

**Decision: Dual target**
1. **WASM** for production deployment (portable, fast, secure sandbox)
2. **Tree-walking interpreter** for development/REPL (Phase 1 prototype)

The interpreter enables rapid iteration during language design. WASM backend follows in Phase 2.

#### JS Interop Layer

Since agents primarily interact with web APIs, a thin JS interop layer handles:
- HTTP requests (`@GET`, `@POST`, etc.) → `fetch()`
- File I/O → Node.js `fs` module
- JSON → native JS objects (zero-cost in WASM+JS)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│                  Source (.arc)               │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│            Lexer (tokenize)                 │
│  - Keyword recognition (24 reserved words)  │
│  - String interpolation segmentation        │
│  - Comment stripping                        │
└─────────────┬───────────────────────────────┘
              │ Token Stream
              ▼
┌─────────────────────────────────────────────┐
│        Parser (recursive descent)           │
│  - Pratt expression parsing                 │
│  - Error recovery at sync points            │
│  - Source span tracking                     │
└─────────────┬───────────────────────────────┘
              │ AST
              ▼
┌─────────────────────────────────────────────┐
│        Semantic Analysis                    │
│  1. Name resolution & scope building        │
│  2. Type inference (HM + constraints)       │
│  3. Type checking & exhaustiveness          │
│  4. Semantic type validation                │
└─────────────┬───────────────────────────────┘
              │ Annotated AST
              ▼
┌─────────────────────────────────────────────┐
│         IR Generation (SSA)                 │
│  - Three-address code                       │
│  - Tool calls → unified call instructions   │
│  - Pattern match → decision trees           │
└─────────────┬───────────────────────────────┘
              │ IR
              ▼
┌─────────────────────────────────────────────┐
│         Optimization Passes                 │
│  - Dead code elimination                    │
│  - Constant folding                         │
│  - Inlining                                 │
│  - Tool call batching                       │
│  - Pipeline fusion                          │
│  - Tail call optimization                   │
└─────────────┬───────────────────────────────┘
              │ Optimized IR
              ▼
┌────────────────────┬────────────────────────┐
│   WASM Codegen     │   Tree-walk Interp     │
│  (production)      │  (dev/REPL)            │
└────────────────────┴────────────────────────┘
```

---

## Implementation Language

**Recommendation: Rust**

| Factor | Rust | TypeScript | Go | C++ |
|--------|------|------------|-----|-----|
| Performance | ✅ Excellent | ❌ GC pauses | ⚠️ Good | ✅ Excellent |
| Safety | ✅ Memory safe | ✅ GC | ⚠️ GC | ❌ Manual |
| WASM support | ✅ First-class | ⚠️ Via wasm-pack | ⚠️ Limited | ⚠️ Emscripten |
| Ecosystem | ✅ nom, logos, cranelift | ✅ Rich | ⚠️ Limited | ⚠️ Legacy |
| Community | ✅ Lang-dev community | ⚠️ Less common | ⚠️ Less common | ✅ Established |

Rust provides memory safety without GC (critical for a compiler), excellent WASM compilation via `wasm-pack`, and a strong ecosystem for language tools (`logos` for lexing, `chumsky` for parsing, `cranelift` for codegen).

**Phase 1 exception:** The prototype interpreter may be written in TypeScript for speed of iteration, then rewritten in Rust for Phase 2.

---

## File Structure

```
compiler/
├── ARCHITECTURE.md       # This document
├── src/
│   ├── lexer/            # Tokenization
│   │   ├── mod.rs
│   │   ├── token.rs      # Token types
│   │   └── tests.rs
│   ├── parser/           # Parsing
│   │   ├── mod.rs
│   │   ├── ast.rs        # AST node definitions
│   │   ├── expr.rs       # Expression parsing (Pratt)
│   │   ├── stmt.rs       # Statement parsing
│   │   └── tests.rs
│   ├── semantic/         # Analysis
│   │   ├── mod.rs
│   │   ├── resolve.rs    # Name resolution
│   │   ├── infer.rs      # Type inference
│   │   ├── check.rs      # Type checking
│   │   └── tests.rs
│   ├── ir/               # Intermediate representation
│   │   ├── mod.rs
│   │   ├── generate.rs   # AST → IR
│   │   └── optimize.rs   # Optimization passes
│   ├── codegen/          # Code generation
│   │   ├── mod.rs
│   │   ├── wasm.rs       # WASM backend
│   │   └── interp.rs     # Tree-walking interpreter
│   └── main.rs           # CLI entry point
├── Cargo.toml
└── tests/
    └── integration/      # End-to-end test cases
```

---

## Token Efficiency in Compiler Design

The compiler itself is designed to be token-efficient to describe and maintain:

1. **Small grammar** — 24 keywords means fewer lexer/parser rules.
2. **Uniform constructs** — Pattern matching unifies conditionals, destructuring, and type dispatch into one mechanism.
3. **Minimal AST nodes** — Expression-oriented design means fewer node types.
4. **Optimization focus** — Tool call batching and pipeline fusion are unique to Arc's agent-oriented workloads.

---

**Last Updated:** 2026-02-16
**Status:** Draft v0.1
