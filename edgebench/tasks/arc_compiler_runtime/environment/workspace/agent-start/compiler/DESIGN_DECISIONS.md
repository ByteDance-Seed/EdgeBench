# Arc Compiler Design Decisions

**Purpose:** Document key architectural decisions with rationale, trade-offs, and alternatives considered.

**Audience:** Compiler contributors, language designers, future maintainers.

**Last Updated:** 2026-02-16

---

## Decision Log

### DD-001: Custom Intermediate Representation (Arc IR)

**Decision:** Implement custom IR (AIR) instead of compiling directly to LLVM IR.

**Rationale:**

1. **Language-Specific Optimizations**
   - Arc patterns, async operations, and tool calls need specialized handling
   - LLVM doesn't understand high-level Arc semantics (pattern exhaustiveness, async fusion)
   - Custom IR enables Arc-aware optimization passes

2. **Multiple Backend Support**
   - AIR can target LLVM, WebAssembly, custom VM, or future backends
   - Decouples language semantics from code generation target
   - Easier to add new backends without reimplementing frontend

3. **Incremental Compilation**
   - AIR can be serialized/cached between compilations
   - Faster than re-lowering to LLVM IR each time
   - Enables query-based incremental architecture

4. **Debugging & Introspection**
   - AIR is higher-level than LLVM IR, easier to understand
   - Better error messages pointing to source code
   - Compiler debugging and visualization tools

**Alternatives Considered:**

- **Direct to LLVM IR:** Faster initial implementation but loses flexibility
- **Use existing IR (Cranelift, MIR):** Not designed for Arc's semantics
- **No IR, direct codegen:** Difficult to optimize, maintain

**Trade-offs:**

- **Pro:** Flexibility, optimization opportunities, maintainability
- **Con:** Additional complexity, more code to maintain
- **Pro:** Better error messages and debugging
- **Con:** Slower initial development

**Verdict:** Benefits outweigh costs. Custom IR is essential for Arc's goals.

---

### DD-002: Primary Backend - LLVM

**Decision:** Use LLVM as primary code generation backend for native executables.

**Rationale:**

1. **Performance**
   - Industry-standard optimization (competitive with C/C++/Rust)
   - Achieves Arc's 30%+ speed improvement target
   - Excellent code generation for all major architectures

2. **Maturity & Ecosystem**
   - Battle-tested by Rust, Swift, Clang, Julia
   - Comprehensive platform support (x86, ARM, RISC-V, etc.)
   - Active development and optimization improvements

3. **Tooling Integration**
   - Debug info generation (DWARF)
   - Profiling support (instrumentation passes)
   - Link-time optimization (LTO)

4. **Development Velocity**
   - Don't reinvent code generation
   - Focus compiler effort on Arc-specific features
   - Leverage decades of optimization research

**Alternatives Considered:**

- **Cranelift:** Faster compilation, but less mature optimization
- **Custom codegen:** Full control, but years of development effort
- **GCC backend:** Less flexible API, harder to integrate

**Trade-offs:**

- **Pro:** Excellent performance, proven technology
- **Con:** Large dependency (~100MB), slower compile times
- **Pro:** Wide platform support
- **Con:** Complex API, steep learning curve

**Mitigation:**
- Use Cranelift for debug builds (fast iteration)
- Cache LLVM IR/bitcode for incremental compilation
- Consider dynamic linking to reduce binary size

**Verdict:** LLVM is the right choice for production performance.

---

### DD-003: Memory Management - Automatic Reference Counting (ARC)

**Decision:** Use automatic reference counting with cycle detection as default memory management strategy.

**Rationale:**

1. **Predictable Performance**
   - No GC pauses (critical for real-time agents)
   - Deterministic deallocation (memory freed immediately)
   - Consistent latency characteristics

2. **Low Overhead**
   - Minimal runtime cost (increment/decrement on assign)
   - No need for stop-the-world collection
   - Better cache locality than tracing GC

3. **Simplicity**
   - Easier to reason about than manual memory management
   - Familiar to Swift/Objective-C developers
   - Straightforward FFI integration

4. **Compatibility**
   - Interoperates with system libraries (C, Swift)
   - No special runtime requirements
   - Easier cross-platform support

**Alternatives Considered:**

- **Tracing GC (Mark-Sweep):** Simpler implementation, unpredictable pauses
- **Manual (Rust-style ownership):** Zero overhead, steep learning curve
- **Hybrid (ARC + escape analysis):** Best performance, complex implementation

**Trade-offs:**

- **Pro:** Predictable, low overhead, simple
- **Con:** Potential reference cycles (requires weak refs)
- **Pro:** No GC pauses
- **Con:** Slightly slower than pure ownership (extra RC ops)

**Mitigation:**
- Cycle detector runs in background thread
- Compiler warnings for potential cycles
- Escape analysis to eliminate unnecessary RC ops
- Future: Optional ownership tracking (strict mode)

**Future Evolution:**
- **Phase 3:** Add escape analysis optimization
- **Phase 4:** Optional borrow checking for zero-cost memory safety
- **Phase 5:** Gradual typing allows opt-in to strict ownership

**Verdict:** ARC strikes the best balance for Phase 0-2. Future phases can add optimizations.

---

### DD-004: Type System - Hindley-Milner + Bidirectional Checking

**Decision:** Implement constraint-based type inference with bidirectional type checking.

**Rationale:**

1. **Inference Over Annotation**
   - Supports Arc's token economy goal
   - Reduces boilerplate (no type annotations for most code)
   - Familiar to ML, Haskell, Rust, Swift developers

2. **Strong Static Guarantees**
   - Catch errors at compile time
   - No `undefined is not a function` at runtime
   - Enables aggressive optimization

3. **Gradual Typing**
   - Optional type annotations for clarity or performance
   - Bidirectional checking propagates expected types
   - Best of both worlds (inference + explicit where needed)

4. **Semantic Types**
   - Support validation predicates (Email, Age, etc.)
   - Compile-time and runtime validation
   - Self-documenting code

**Alternatives Considered:**

- **Pure inference (HM only):** Simple but limited expressiveness
- **Annotation required (C/Java):** Verbose, violates token economy
- **Dynamic typing (Python/JS):** Fast prototyping, runtime errors
- **Structural typing (TypeScript):** Complex, slow type checking

**Trade-offs:**

- **Pro:** Excellent error catching, minimal annotations
- **Con:** Type errors can be confusing for beginners
- **Pro:** Enables powerful optimizations
- **Con:** Inference algorithm is complex

**Implementation Strategy:**

1. **Phase 1:** Basic Hindley-Milner inference
2. **Phase 2:** Add bidirectional checking for better errors
3. **Phase 3:** Semantic type validation
4. **Phase 4:** Advanced features (higher-kinded types, effect system)

**Verdict:** HM + bidirectional checking matches Arc's philosophy perfectly.

---

### DD-005: Async Compilation - State Machines

**Decision:** Compile async/await to state machines (like Rust), not stackful coroutines.

**Rationale:**

1. **Zero-Cost Abstraction**
   - State machines have minimal overhead
   - No separate stack allocation
   - Compiler can inline and optimize aggressively

2. **Compatibility**
   - Works with all backends (LLVM, WASM, VM)
   - No OS-specific coroutine support required
   - Easier to implement than stackful coroutines

3. **Composability**
   - Futures can be combined, cancelled, raced
   - Works with work-stealing scheduler
   - Enables async optimizations (fusion, batching)

**Alternatives Considered:**

- **Stackful coroutines (Go-style):** Simple runtime, high memory overhead
- **Callbacks (JavaScript):** Callback hell, hard to optimize
- **Green threads:** Complex runtime, difficult to implement
- **OS threads:** Too heavy, not scalable for thousands of operations

**Trade-offs:**

- **Pro:** Zero-cost, composable, optimizer-friendly
- **Con:** Complex compilation (state machine generation)
- **Pro:** Minimal runtime overhead
- **Con:** Debugging can be harder (transformed code)

**Implementation Notes:**

Each `await` point splits function into states:
```arc
fn example() async {
  let x = await operation1()  // State 0 → 1
  let y = await operation2(x) // State 1 → 2
  return x + y                // State 2 → done
}

// Compiles to:
enum State { S0, S1, S2, Done }
struct ExampleFuture {
  state: State
  x: Option<T>
  y: Option<U>
}
```

**Verdict:** State machines are the right approach for Arc's async model.

---

### DD-006: Pattern Compilation - Decision Trees

**Decision:** Compile pattern matching to optimized decision trees, not naive if-else chains.

**Rationale:**

1. **Performance**
   - Decision trees minimize redundant checks
   - Jump tables for literal patterns
   - Early exit for common cases

2. **Exhaustiveness Checking**
   - Decision tree construction reveals missing patterns
   - Compile-time guarantee of completeness
   - Better error messages

3. **Optimization Opportunities**
   - Reorder patterns for optimal performance
   - Merge common branches
   - Specialize for monomorphic types

**Example:**

```arc
match (x, y) {
  (0, 0) => "origin"
  (0, _) => "y-axis"
  (_, 0) => "x-axis"
  (a, b) => "quadrant"
}

// Naive: 4 checks per match
// Optimized: 2-3 checks (test x first, branch on result)
```

**Alternatives Considered:**

- **Naive if-else:** Simple, slow, redundant checks
- **Jump tables only:** Fast for literals, doesn't handle guards
- **Backtracking:** Flexible, complex, potentially slow

**Trade-offs:**

- **Pro:** Optimal performance for common patterns
- **Con:** Complex compilation algorithm
- **Pro:** Exhaustiveness checking
- **Con:** Slower compile times

**Implementation:**
- Use *pattern matrix* algorithm (similar to Rust, OCaml)
- Generate decision tree during IR generation
- Optimize with heuristics (test most discriminating patterns first)

**Verdict:** Decision trees are essential for Arc's pattern-first design.

---

### DD-007: Optimization Philosophy - Aggressive by Default

**Decision:** Apply aggressive optimizations at -O2 (default release mode).

**Rationale:**

1. **Performance Goals**
   - 30%+ speed improvement requires aggressive optimization
   - Zero-cost abstractions need inlining, specialization
   - Arc prioritizes runtime performance

2. **Developer Experience**
   - Developers expect fast code without flags
   - `-O2` should "just work" for production
   - Debug builds (-O0) for fast iteration

3. **Competitive Positioning**
   - Rust, Swift use aggressive optimization by default
   - Matches expectations of systems programmers
   - Differentiates from interpreted languages

**Optimization Tiers:**

- **-O0:** No optimization (debug, fast compile)
- **-O1:** Basic optimization (balanced)
- **-O2:** Aggressive (default release, ~2-5x faster than -O0)
- **-O3:** Maximum (may increase binary size, longer compile)
- **-Os:** Size optimization (embedded, WASM)

**Key Optimizations at -O2:**
- Function inlining (aggressive for small functions)
- Pattern specialization (monomorphization)
- Async fusion (batch concurrent operations)
- Common subexpression elimination
- Dead code elimination
- Constant folding/propagation

**Trade-offs:**

- **Pro:** Fast by default, matches user expectations
- **Con:** Longer compile times
- **Pro:** Enables zero-cost abstractions
- **Con:** Harder to debug optimized code

**Mitigation:**
- Debug builds use -O0 by default
- Source maps for release debugging
- Flags to disable specific optimizations
- Incremental compilation to amortize cost

**Verdict:** Aggressive optimization by default aligns with Arc's performance goals.

---

### DD-008: Error Messages - Developer-Friendly First

**Decision:** Prioritize clear, actionable error messages over compile speed.

**Rationale:**

1. **Developer Productivity**
   - Good errors save hours of debugging
   - First-time users need helpful guidance
   - Reduces frustration, increases adoption

2. **Arc's Complexity**
   - Type inference errors can be cryptic
   - Pattern matching failures need context
   - Async errors span multiple functions

3. **Competitive Advantage**
   - Rust's error messages are a major selling point
   - Elm's errors set industry standard
   - Arc can differentiate here

**Error Message Principles:**

1. **Show the Problem:** Highlight exact location with context
2. **Explain Why:** What went wrong and why
3. **Suggest Fix:** Concrete next steps
4. **Be Kind:** Assume the user is smart but made a mistake

**Example:**

```
error[E0308]: Type mismatch in function call
  --> src/main.arc:12:18
   |
12 |   let result = double("hello")
   |                ^^^^^^^^^^^^^^^ expected Int, found String
   |                |
   |                this function expects an integer
   |
help: `double` is defined as:
  --> src/main.arc:5:1
   |
 5 | fn double(x: Int) => x * 2
   |           ------     ^^^^^ multiplies by 2
   |           |
   |           expects integer argument
   |
note: If you want to double a string, use `repeat`:
   |
12 |   let result = "hello".repeat(2)
   |                ~~~~~~~~~~~~~~~~~
```

**Trade-offs:**

- **Pro:** Better developer experience
- **Con:** Slower error reporting (more analysis)
- **Pro:** Easier language adoption
- **Con:** More code to maintain

**Implementation:**
- Store full source context during parsing
- Multi-pass error analysis for suggestions
- Template-based error formatting
- Error code system for documentation

**Verdict:** Excellent error messages are worth the investment.

---

### DD-009: Compilation Speed - Balanced Approach

**Decision:** Target sub-5-second cold builds for 10K LOC, prioritize incremental compilation.

**Rationale:**

1. **Developer Experience**
   - Fast feedback loop during development
   - Incremental < 500ms feels instant
   - Cold build < 5s acceptable for medium projects

2. **Realistic Performance**
   - Rust/Swift compile slowly (aggressive optimization)
   - Go/TypeScript compile quickly (less optimization)
   - Arc targets middle ground

3. **Incremental First**
   - Most builds are incremental (change 1 file)
   - Cache aggressively at module granularity
   - Query-based architecture enables smart invalidation

**Strategies:**

1. **Parallel Compilation:** Per-module parallelism
2. **Incremental Analysis:** Cache type information
3. **Lazy Loading:** Don't parse unused modules
4. **Fast Debug Builds:** -O0 skips optimization
5. **Separate Release Builds:** -O2 for production

**Benchmarks (Target):**

| Project Size | Cold Build | Incremental | Release Build |
|--------------|------------|-------------|---------------|
| 1K LOC       | < 500ms    | < 100ms     | < 2s          |
| 10K LOC      | < 5s       | < 500ms     | < 20s         |
| 100K LOC     | < 60s      | < 2s        | < 5min        |

**Trade-offs:**

- **Pro:** Good developer experience
- **Con:** Slower than Go (no type checking optimization)
- **Pro:** Incremental is fast
- **Con:** Cold builds slower than interpreted languages

**Verdict:** Balanced approach prioritizes incremental speed.

---

### DD-010: WebAssembly Support - First-Class Target

**Decision:** Support WebAssembly as first-class compilation target (not afterthought).

**Rationale:**

1. **Universal Deployment**
   - Run in browsers (frontend agents)
   - Run in Node.js, Deno, Bun (backend)
   - Run in edge compute (Cloudflare, Fastly)
   - Run in embedded systems (WASI support)

2. **Sandboxed Execution**
   - Safe untrusted code execution
   - Capability-based security
   - Important for AI agent deployment

3. **Near-Native Performance**
   - WASM is 1-2x slower than native (acceptable)
   - Much faster than JavaScript
   - Supports Arc's performance goals

4. **Small Bundle Size**
   - Tree-shaking eliminates unused code
   - < 1MB runtime for minimal programs
   - Important for web deployment

**Challenges:**

- **Garbage Collection:** WASM GC proposal or manual management
- **Async Integration:** Interop with JavaScript Promises
- **System Calls:** WASI for file/network access

**Implementation:**

1. **Phase 2:** Basic WASM codegen (no GC, manual memory)
2. **Phase 3:** WASM GC integration when stable
3. **Phase 4:** Full WASI support for system access

**Trade-offs:**

- **Pro:** Universal deployment, safety
- **Con:** Slightly slower than native
- **Pro:** Small bundle size
- **Con:** Limited system access (WASI still maturing)

**Verdict:** WASM is critical for Arc's vision of universal agent deployment.

---

### DD-011: Standard Library - Batteries Included

**Decision:** Include comprehensive standard library with HTTP, JSON, file I/O built-in.

**Rationale:**

1. **Developer Productivity**
   - AI agents need HTTP, JSON, files in 90% of tasks
   - No time wasted on dependency management
   - Reduces token count (no import boilerplate)

2. **Consistency**
   - Single API design across all I/O
   - Integrated error handling
   - Optimized for Arc's async model

3. **Security**
   - Vetted, maintained implementations
   - No supply chain attacks from npm/PyPI
   - Easier to audit

4. **Performance**
   - Stdlib can be optimized by compiler
   - Inlining across stdlib boundaries
   - Custom allocators for stdlib types

**Included Modules:**

- **Core:** String, List, Map, Set, Option, Result
- **I/O:** File, Path, Stream
- **Network:** HTTP client/server, WebSockets
- **Data:** JSON, CSV, XML (optional)
- **Async:** Task, Channel, Timer
- **Crypto:** Hashing, encryption (future)
- **Testing:** Test framework, assertions

**Trade-offs:**

- **Pro:** Productive out-of-the-box
- **Con:** Larger initial binary size
- **Pro:** Consistent APIs
- **Con:** Slower stdlib evolution vs ecosystem packages

**Mitigation:**
- Tree-shaking eliminates unused modules
- Plugin system for extended functionality
- Versioned stdlib for stability

**Verdict:** Batteries-included stdlib matches Arc's philosophy.

---

### DD-012: Tool Call Syntax - First-Class Integration

**Decision:** Make HTTP, file, and database operations first-class syntax (not library calls).

**Rationale:**

1. **Token Efficiency**
   - `GET api/users/1` vs `http.get("api/users/1")`
   - Reduces boilerplate for 90% of agent operations
   - Matches Arc's token economy goal

2. **Type Safety**
   - Compiler can validate endpoints at compile-time
   - Better error messages for malformed requests
   - Static analysis of API usage

3. **Optimization Opportunities**
   - Compiler can batch parallel requests
   - Automatic retry logic
   - Connection pooling optimizations

4. **Readability**
   - Code reads like API documentation
   - Clear intent (GET vs POST vs PUT)
   - Less cognitive load

**Syntax Examples:**

```arc
// HTTP
user = GET api/users/:id
POST api/users {name, email}
PUT api/users/:id user
DELETE api/users/:id

// Files
data = read "file.txt"
write "output.txt" data
append "log.txt" message

// Database (future)
users = SELECT * FROM users WHERE age > 18
INSERT INTO users {name, email}
```

**Trade-offs:**

- **Pro:** Concise, readable, optimizable
- **Con:** More parser complexity
- **Pro:** First-class optimization
- **Con:** Less flexible than library (fixed API)

**Implementation:**
- Parse as special expression forms
- Lower to stdlib calls in IR
- Stdlib provides actual implementation
- Allows evolution without syntax changes

**Verdict:** First-class tool syntax is core to Arc's value proposition.

---

## Decision Matrix Summary

| Decision | Priority | Complexity | Phase |
|----------|----------|------------|-------|
| DD-001: Custom IR | Critical | High | 1 |
| DD-002: LLVM Backend | Critical | Medium | 2 |
| DD-003: ARC Memory | Critical | Medium | 2 |
| DD-004: HM Type System | Critical | High | 1 |
| DD-005: Async State Machines | Critical | High | 2 |
| DD-006: Pattern Decision Trees | High | High | 1 |
| DD-007: Aggressive Optimization | High | Medium | 2 |
| DD-008: Error Messages | High | Medium | 1 |
| DD-009: Incremental Compilation | Medium | High | 3 |
| DD-010: WASM Support | High | Medium | 2-3 |
| DD-011: Batteries-Included Stdlib | Medium | Medium | 3 |
| DD-012: Tool Call Syntax | Critical | Medium | 1 |

---

## Review & Evolution

**Review Cycle:** Every 4 weeks or when major issues arise.

**Change Process:**
1. Identify problem with current approach
2. Document alternatives and trade-offs
3. Discuss in GitHub Issues
4. Update this document with decision
5. Implement changes with migration plan

**Living Document:** This document evolves as Arc matures. All changes are tracked in git history.

---

**Author:** Subagent 2 (Arc Compiler Architect)  
**Status:** Phase 0 - Design Document  
**Next Review:** Phase 1 completion (Week 6)
