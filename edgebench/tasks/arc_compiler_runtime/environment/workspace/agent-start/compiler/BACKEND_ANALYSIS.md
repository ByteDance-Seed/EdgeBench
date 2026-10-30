# Arc Compiler Backend Analysis

**Purpose:** Comprehensive evaluation of code generation backends for Arc.

**Author:** Subagent 2 (Arc Compiler Architect)  
**Last Updated:** 2026-02-16  
**Status:** Phase 0 - Research & Decision Document

---

## Executive Summary

**Recommended Strategy:**
1. **Phase 2 (Weeks 7-10):** LLVM backend for native performance
2. **Phase 3 (Weeks 13-16):** WebAssembly backend for universal deployment
3. **Phase 4+ (Optional):** Custom VM for development/debugging

This phased approach prioritizes production performance (LLVM) while planning for web deployment (WASM) and developer experience (VM).

---

## Backend Comparison Matrix

| Criteria | LLVM | WebAssembly | Cranelift | Custom VM | JavaScript |
|----------|------|-------------|-----------|-----------|------------|
| **Performance** | ⭐⭐⭐⭐⭐ (best) | ⭐⭐⭐⭐ (near-native) | ⭐⭐⭐⭐ (good) | ⭐⭐ (slow) | ⭐⭐ (V8-dependent) |
| **Compile Speed** | ⭐⭐ (slow) | ⭐⭐⭐ (moderate) | ⭐⭐⭐⭐⭐ (fast) | ⭐⭐⭐⭐⭐ (fast) | ⭐⭐⭐⭐ (fast) |
| **Binary Size** | ⭐⭐⭐ (moderate) | ⭐⭐⭐⭐⭐ (tiny) | ⭐⭐⭐ (moderate) | ⭐⭐⭐⭐ (small) | ⭐⭐⭐⭐ (small) |
| **Platform Support** | ⭐⭐⭐⭐⭐ (universal) | ⭐⭐⭐⭐⭐ (browser+WASI) | ⭐⭐⭐⭐ (major platforms) | ⭐⭐⭐⭐⭐ (portable bytecode) | ⭐⭐⭐⭐⭐ (everywhere) |
| **Debugging** | ⭐⭐⭐⭐ (DWARF) | ⭐⭐⭐ (SourceMaps) | ⭐⭐⭐ (limited) | ⭐⭐⭐⭐⭐ (excellent) | ⭐⭐⭐⭐ (browser tools) |
| **Maturity** | ⭐⭐⭐⭐⭐ (battle-tested) | ⭐⭐⭐⭐ (maturing) | ⭐⭐⭐ (young) | ⭐ (DIY) | ⭐⭐⭐⭐⭐ (proven) |
| **Development Effort** | ⭐⭐ (complex API) | ⭐⭐⭐ (moderate) | ⭐⭐⭐⭐ (simpler) | ⭐ (high effort) | ⭐⭐⭐⭐⭐ (easy) |
| **Optimization** | ⭐⭐⭐⭐⭐ (world-class) | ⭐⭐⭐⭐ (good) | ⭐⭐⭐ (basic) | ⭐⭐ (manual) | ⭐⭐⭐⭐ (V8 handles) |

**Verdict:** Use LLVM for production, WASM for web, consider Custom VM for dev tooling.

---

## 1. LLVM Backend (Primary Target)

### Overview

LLVM (Low Level Virtual Machine) is an industry-standard compiler infrastructure providing reusable components for building optimizing compilers.

**Used by:** Rust, Swift, Clang (C/C++), Julia, Crystal, Kotlin Native

### Architecture

```
Arc IR (AIR)
    ↓
LLVM IR Generator
    ↓
LLVM IR (.ll or bitcode)
    ↓
LLVM Optimization Passes
    ↓
LLVM Code Generation
    ↓
Object File (.o)
    ↓
System Linker (ld, lld)
    ↓
Executable Binary
```

### Advantages

#### 1. World-Class Performance
- **Mature Optimizations:** 100+ optimization passes (inlining, loop unrolling, vectorization, etc.)
- **Competitive with C/C++:** Achieves Arc's 30%+ speed target
- **Cross-platform:** Native code for x86, ARM, RISC-V, WebAssembly, and more

#### 2. Rich Ecosystem
- **Debug Info:** DWARF generation for GDB, LLDB
- **Profiling:** Instrumentation support (PGO - Profile-Guided Optimization)
- **Sanitizers:** AddressSanitizer, ThreadSanitizer for detecting bugs
- **LTO:** Link-Time Optimization across modules

#### 3. Proven Technology
- **Battle-tested:** Used in production by Apple (Swift), Mozilla (Rust), Google (Android NDK)
- **Active Development:** Continuous optimization improvements
- **Documentation:** Extensive documentation and examples

#### 4. Future-Proof
- **MLIR Integration:** Multi-Level IR for advanced optimization
- **WebAssembly Support:** LLVM can target WASM directly
- **GPU Support:** NVPTX backend for CUDA, AMDGPU for ROCm

### Disadvantages

#### 1. Complexity
- **Large API Surface:** C++ API with thousands of functions
- **Steep Learning Curve:** LLVM IR is lower-level than source languages
- **Version Stability:** API changes between LLVM versions

#### 2. Compile Speed
- **Slow Optimization:** -O2 can be 10x slower than no optimization
- **Large Binary:** LLVM dependency adds ~100MB to compiler
- **Cold Start:** First compilation slower than Cranelift

#### 3. Integration Overhead
- **FFI Complexity:** Calling LLVM from Rust/other languages requires bindings
- **Build System:** Requires linking against LLVM libraries
- **Deployment:** Users need compatible LLVM version

### Implementation Strategy

#### AIR → LLVM IR Translation

**Type Mapping:**
```
Arc Type      → LLVM Type
Int           → i64
Float         → double
Bool          → i1
String        → ptr (to heap-allocated struct)
List<T>       → ptr (to dynamic array struct)
Function      → function pointer
```

**Memory Model:**
```rust
// Arc object representation in LLVM
%Object = type {
    i64,        // Reference count
    i64,        // Type ID
    ptr         // Data pointer
}

// List<T> representation
%List = type {
    %Object,    // Object header
    i64,        // Length
    i64,        // Capacity
    ptr         // Data pointer
}
```

**Function Translation:**
```arc
// Arc source
fn add(a: Int, b: Int) -> Int {
    a + b
}

// LLVM IR
define i64 @add(i64 %a, i64 %b) {
entry:
    %result = add i64 %a, %b
    ret i64 %result
}
```

**Pattern Match Compilation:**
```arc
// Arc match
match x {
    0 => "zero"
    1 => "one"
    _ => "other"
}

// LLVM IR (simplified)
switch i64 %x, label %default [
    i64 0, label %case_zero
    i64 1, label %case_one
]

case_zero:
    ret ptr @str_zero

case_one:
    ret ptr @str_one

default:
    ret ptr @str_other
```

#### Rust Integration (If Implementing in Rust)

```rust
use llvm_sys::core::*;
use llvm_sys::prelude::*;
use llvm_sys::target::*;

pub struct LLVMCodegen {
    context: LLVMContextRef,
    module: LLVMModuleRef,
    builder: LLVMBuilderRef,
}

impl LLVMCodegen {
    pub fn new(module_name: &str) -> Self {
        unsafe {
            let context = LLVMContextCreate();
            let module = LLVMModuleCreateWithNameInContext(
                module_name.as_ptr() as *const _,
                context
            );
            let builder = LLVMCreateBuilderInContext(context);
            
            Self { context, module, builder }
        }
    }
    
    pub fn compile_function(&mut self, func: &Function) -> LLVMValueRef {
        // Translate Arc function to LLVM function
        unsafe {
            let func_type = self.translate_function_type(func);
            let llvm_func = LLVMAddFunction(
                self.module,
                func.name.as_ptr() as *const _,
                func_type
            );
            
            // Create entry block
            let entry_bb = LLVMAppendBasicBlockInContext(
                self.context,
                llvm_func,
                b"entry\0".as_ptr() as *const _
            );
            
            LLVMPositionBuilderAtEnd(self.builder, entry_bb);
            
            // Compile function body
            for block in &func.blocks {
                self.compile_block(block);
            }
            
            llvm_func
        }
    }
}
```

### Optimization Pipeline

```rust
use llvm_sys::transforms::pass_manager_builder::*;

fn optimize_module(module: LLVMModuleRef, opt_level: u32) {
    unsafe {
        let pmb = LLVMPassManagerBuilderCreate();
        LLVMPassManagerBuilderSetOptLevel(pmb, opt_level);
        
        let pm = LLVMCreatePassManager();
        LLVMPassManagerBuilderPopulateModulePassManager(pmb, pm);
        
        // Run optimization passes
        LLVMRunPassManager(pm, module);
        
        LLVMDisposePassManager(pm);
        LLVMPassManagerBuilderDispose(pmb);
    }
}
```

### Performance Targets

| Benchmark | Target Performance | vs JavaScript V8 |
|-----------|-------------------|------------------|
| Numeric Computation | 30-50x faster | ⭐⭐⭐⭐⭐ |
| String Manipulation | 3-5x faster | ⭐⭐⭐⭐ |
| Memory-Intensive | 10-20x faster | ⭐⭐⭐⭐⭐ |
| I/O Bound | Similar | ⭐⭐⭐ |

### Challenges & Mitigations

**Challenge 1: Garbage Collection**
- **Problem:** LLVM doesn't provide GC
- **Solution:** Implement ARC in generated code (RC increment/decrement)

**Challenge 2: Async Runtime**
- **Problem:** LLVM doesn't understand async
- **Solution:** Compile async to state machines, runtime scheduler

**Challenge 3: Debug Experience**
- **Problem:** Optimized code hard to debug
- **Solution:** Generate DWARF debug info, provide -O0 builds

### Resources

- **LLVM Documentation:** https://llvm.org/docs/
- **LLVM Language Reference:** https://llvm.org/docs/LangRef.html
- **llvm-sys Crate:** https://crates.io/crates/llvm-sys
- **Kaleidoscope Tutorial:** https://llvm.org/docs/tutorial/

---

## 2. WebAssembly Backend (Web/Universal Target)

### Overview

WebAssembly (WASM) is a binary instruction format for a stack-based virtual machine, designed as a portable compilation target for high-level languages.

**Used by:** Rust (wasm-bindgen), C/C++ (Emscripten), Go, AssemblyScript

### Architecture

```
Arc IR (AIR)
    ↓
WASM Code Generator
    ↓
WASM Binary (.wasm)
    ↓
Runtime (Browser, Node.js, Wasmtime, Wasmer)
    ↓
Execution
```

### Advantages

#### 1. Universal Deployment
- **Browsers:** Run in all modern browsers (Chrome, Firefox, Safari, Edge)
- **Server-Side:** Node.js, Deno, Bun support WASM
- **Edge Computing:** Cloudflare Workers, Fastly Compute@Edge
- **Embedded:** WASM on microcontrollers, IoT devices

#### 2. Sandboxed Security
- **Memory Safety:** Linear memory with bounds checking
- **Capability-Based:** WASI provides secure system access
- **No Ambient Authority:** Explicit permission model

#### 3. Small Binary Size
- **Tree-Shaking:** Eliminate unused functions
- **Compression:** brotli/gzip reduces size by 50-70%
- **Target:** < 1MB for minimal Arc runtime

#### 4. Near-Native Performance
- **JIT Compilation:** Browsers JIT-compile WASM to native
- **SIMD Support:** SIMD instructions for parallel operations
- **1-2x Slower:** Typically 1-2x slower than native, much faster than JS

### Disadvantages

#### 1. Garbage Collection Challenges
- **GC Proposal:** WASM GC proposal still experimental (2026)
- **Manual Memory:** Must manage memory manually or implement ARC
- **Interop Overhead:** GC objects can't cross JS/WASM boundary efficiently

#### 2. Async Integration
- **No Native Async:** WASM has no async primitives
- **JS Promise Interop:** Must integrate with JavaScript Promises
- **Complexity:** State machine compilation + JS glue code

#### 3. System Access Limitations
- **WASI Maturity:** WASI (WebAssembly System Interface) still evolving
- **Limited APIs:** No direct access to sockets, threads (in browsers)
- **Polyfills Required:** Some features need JavaScript polyfills

#### 4. Debugging Experience
- **Limited Tooling:** Debugging WASM is harder than native
- **SourceMaps:** Requires source maps for debugging
- **Browser DevTools:** Improving but not perfect

### Implementation Strategy

#### AIR → WASM Translation

**Type Mapping:**
```
Arc Type      → WASM Type
Int           → i64
Float         → f64
Bool          → i32 (0 or 1)
String        → i32 (pointer to linear memory)
Object        → i32 (pointer to linear memory)
```

**Memory Layout:**
```
WASM Linear Memory:
[0-64KB]      → Stack (local variables)
[64KB-...]    → Heap (objects, strings, arrays)

Object Header (16 bytes):
[0-7]   → Reference count (i64)
[8-15]  → Type ID (i64)
[16+]   → Object data
```

**Function Translation:**
```arc
// Arc source
fn add(a: Int, b: Int) -> Int {
    a + b
}

// WASM (WAT text format)
(func $add (param $a i64) (param $b i64) (result i64)
    local.get $a
    local.get $b
    i64.add
)
```

**Pattern Match Compilation:**
```wat
;; switch-style match
(block $match_end
    (block $case_1
        (block $case_0
            local.get $x
            i64.const 0
            i64.eq
            br_if $case_0
            
            local.get $x
            i64.const 1
            i64.eq
            br_if $case_1
            
            ;; default case
            ...
            br $match_end
        )
        ;; case 0
        ...
        br $match_end
    )
    ;; case 1
    ...
)
```

#### Rust Integration (wasm-encoder)

```rust
use wasm_encoder::{
    CodeSection, Function, FunctionSection, Instruction, Module,
    TypeSection, ValType,
};

pub struct WasmCodegen {
    module: Module,
    functions: Vec<Function>,
}

impl WasmCodegen {
    pub fn new() -> Self {
        Self {
            module: Module::new(),
            functions: Vec::new(),
        }
    }
    
    pub fn compile_function(&mut self, func: &arc::Function) {
        let mut wasm_func = Function::new(vec![]);
        
        for instruction in &func.instructions {
            match instruction {
                Instruction::Add => {
                    wasm_func.instruction(&Instruction::I64Add);
                }
                Instruction::Call(idx) => {
                    wasm_func.instruction(&Instruction::Call(*idx));
                }
                // ... more instructions
            }
        }
        
        self.functions.push(wasm_func);
    }
    
    pub fn emit(&self) -> Vec<u8> {
        let mut module = Module::new();
        
        // Add type section
        let mut types = TypeSection::new();
        // ... add function types
        
        // Add function section
        let mut functions = FunctionSection::new();
        // ... add functions
        
        // Add code section
        let mut code = CodeSection::new();
        for func in &self.functions {
            code.function(func);
        }
        
        module.section(&types);
        module.section(&functions);
        module.section(&code);
        
        module.finish()
    }
}
```

#### WASI Integration

```rust
// System calls via WASI
(import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))

// Arc file write becomes WASI call
fn arc_write_file(path: String, content: String) {
    // Open file via wasi::path_open
    let fd = wasi::path_open(...);
    
    // Write via wasi::fd_write
    wasi::fd_write(fd, content.as_ptr(), content.len(), ...);
    
    // Close via wasi::fd_close
    wasi::fd_close(fd);
}
```

### Performance Targets

| Benchmark | Target Performance | vs JavaScript V8 |
|-----------|-------------------|------------------|
| Numeric Computation | 20-30x faster | ⭐⭐⭐⭐⭐ |
| String Manipulation | 2-3x faster | ⭐⭐⭐ |
| Memory-Intensive | 5-10x faster | ⭐⭐⭐⭐ |
| I/O Bound | Similar | ⭐⭐⭐ |

### Challenges & Mitigations

**Challenge 1: GC Integration**
- **Problem:** WASM GC proposal not widely supported yet
- **Solution Phase 2:** Implement ARC manually
- **Solution Phase 3:** Use WASM GC when stable

**Challenge 2: Async/Promise Interop**
- **Problem:** WASM functions can't directly return Promises
- **Solution:** Generate JS glue code for async functions

```javascript
// Generated JS glue
export async function arc_fetch_user(id) {
    const state_machine = wasm.create_fetch_user_state(id);
    
    while (!state_machine.is_done()) {
        const result = await state_machine.step();
        if (result.is_awaiting()) {
            // Handle async operation
        }
    }
    
    return state_machine.result();
}
```

**Challenge 3: Binary Size**
- **Problem:** Arc runtime adds overhead
- **Solution:** Aggressive tree-shaking, optional features

### Resources

- **WebAssembly Specification:** https://webassembly.github.io/spec/
- **wasm-encoder:** https://crates.io/crates/wasm-encoder
- **WASI:** https://wasi.dev/
- **Wasmtime (runtime):** https://wasmtime.dev/

---

## 3. Cranelift Backend (Alternative Native)

### Overview

Cranelift is a code generator designed for fast compilation, primarily used in Wasmtime for JIT compilation.

**Used by:** Wasmtime, Lucet, Firefox SpiderMonkey (WASM JIT)

### Advantages

- **Fast Compilation:** 10-100x faster than LLVM
- **Good Performance:** 80-90% of LLVM performance
- **Simpler API:** Easier to integrate than LLVM
- **Pure Rust:** No C++ dependencies

### Disadvantages

- **Less Mature:** Younger project, fewer optimizations
- **Limited Platforms:** Fewer architectures than LLVM
- **Smaller Ecosystem:** Less tooling, documentation

### Recommendation

**Consider for:** Debug builds (fast iteration), JIT compilation (future)  
**Not recommended for:** Initial implementation (LLVM better for learning)

---

## 4. Custom VM Backend (Optional Development Tool)

### Overview

A custom bytecode VM specifically designed for Arc, optimized for debugging and development.

### Architecture

```
Arc IR (AIR)
    ↓
Bytecode Generator
    ↓
Arc Bytecode (.arcvm)
    ↓
Arc VM Interpreter
    ↓
Execution
```

### Advantages

#### 1. Excellent Debugging
- **Full Control:** Inspect every instruction, variable, stack frame
- **Time Travel:** Record execution, step backward
- **Tracing:** Built-in tracing, profiling, coverage

#### 2. Fast Iteration
- **Instant Startup:** No compilation, just load bytecode
- **Hot Reload:** Modify code without restarting
- **REPL-Friendly:** Evaluate expressions interactively

#### 3. Portable
- **Platform Independent:** Bytecode runs anywhere VM is ported
- **Consistent Behavior:** No platform-specific quirks
- **Embedded:** Lightweight VM for embedded systems

### Disadvantages

- **Slow Performance:** 10-50x slower than native
- **High Effort:** Building VM from scratch is significant work
- **Maintenance Burden:** Another codebase to maintain

### Bytecode Design

```
Stack-Based VM:

Instructions (1 byte opcode + operands):
0x01  LOAD_CONST  <idx>       // Push constant to stack
0x02  LOAD_VAR    <idx>       // Push variable to stack
0x03  STORE_VAR   <idx>       // Pop stack, store in variable
0x10  ADD                     // Pop 2, push sum
0x11  SUB                     // Pop 2, push difference
0x12  MUL                     // Pop 2, push product
0x13  DIV                     // Pop 2, push quotient
0x20  CALL        <func_idx> <arg_count>
0x21  RETURN
0x30  JUMP        <offset>
0x31  JUMP_IF     <offset>
0x32  JUMP_UNLESS <offset>
0x40  MATCH       <case_count>
0xFF  HALT
```

**Example:**
```arc
fn double(x) => x * 2

Bytecode:
LOAD_VAR 0        // Load parameter x
LOAD_CONST 2      // Push constant 2
MUL               // Multiply
RETURN            // Return result
```

### Implementation (Minimal VM)

```rust
pub struct VM {
    stack: Vec<Value>,
    globals: Vec<Value>,
    call_stack: Vec<CallFrame>,
    ip: usize,
}

impl VM {
    pub fn execute(&mut self, bytecode: &[u8]) -> Result<Value, VMError> {
        loop {
            let opcode = bytecode[self.ip];
            self.ip += 1;
            
            match opcode {
                OP_LOAD_CONST => {
                    let idx = self.read_u16(bytecode);
                    let value = self.constants[idx as usize].clone();
                    self.stack.push(value);
                }
                
                OP_ADD => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    self.stack.push(a + b);
                }
                
                OP_CALL => {
                    let func_idx = self.read_u16(bytecode);
                    let arg_count = self.read_u8(bytecode);
                    self.call_function(func_idx, arg_count)?;
                }
                
                OP_RETURN => {
                    let result = self.stack.pop().unwrap();
                    self.return_from_call()?;
                    self.stack.push(result);
                }
                
                OP_HALT => {
                    return Ok(self.stack.pop().unwrap());
                }
                
                _ => return Err(VMError::InvalidOpcode(opcode)),
            }
        }
    }
}
```

### Recommendation

**Phase 4+:** Implement if debugging experience needs improvement  
**Not critical:** LLVM debug builds sufficient for Phase 0-3

---

## 5. JavaScript Backend (Debug/Compatibility Only)

### Overview

Transpile Arc to JavaScript for debugging and compatibility testing.

### Advantages

- **Instant Deployment:** Run anywhere JavaScript runs
- **Easy Debugging:** Use browser DevTools
- **Interop:** Seamless integration with JS ecosystem

### Disadvantages

- **Poor Performance:** No better than writing JS directly
- **Loses Arc Benefits:** Defeats purpose of Arc

### Recommendation

**Use case:** Debugging compiler pipeline, testing semantics  
**Not for production:** Use WASM instead

---

## Backend Implementation Priority

### Phase 2 (Weeks 7-10): LLVM Backend
- **Goal:** Production-ready native compilation
- **Deliverables:**
  - AIR → LLVM IR translation
  - Memory management (ARC) in LLVM
  - Optimization pipeline
  - Executable generation
  - Benchmarking suite

### Phase 3 (Weeks 13-16): WebAssembly Backend
- **Goal:** Web and universal deployment
- **Deliverables:**
  - AIR → WASM translation
  - WASI integration for file/network
  - JS interop for async operations
  - Tree-shaking for binary size
  - Browser testing

### Phase 4+ (Future): Optional Enhancements
- **Cranelift:** Fast debug builds
- **Custom VM:** Enhanced debugging
- **MLIR:** Advanced optimizations

---

## Conclusion

**Recommended path:**

1. **Start with LLVM (Phase 2):** Achieves performance goals, proven technology
2. **Add WASM (Phase 3):** Universal deployment, sandboxed execution
3. **Consider Cranelift (Phase 4):** If debug compile times become issue
4. **Custom VM (Phase 5+):** Only if debugging experience needs improvement

This strategy balances performance, portability, and development effort while meeting Arc's goals.

---

**Author:** Subagent 2 (Arc Compiler Architect)  
**Status:** Phase 0 - Research Complete  
**Next Steps:** Begin LLVM backend implementation in Phase 2
