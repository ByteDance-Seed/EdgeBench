# Arc Compiler ⚡

The compiler/interpreter implementation for the [Arc programming language](#).

## Architecture

```
src/
├── index.ts           # CLI entry point
├── lexer.ts           # Tokenizer
├── parser.ts          # Parser → AST
├── ast.ts             # AST node types
├── interpreter.ts     # Tree-walking interpreter
├── modules.ts         # Module resolver & loader
├── ir.ts              # Intermediate representation
├── optimizer.ts       # IR optimizer
├── codegen.ts         # WAT code generation
├── codegen-js.ts      # JavaScript code generation
├── semantic.ts        # Semantic analysis
├── typechecker.ts     # Type checker
├── formatter.ts       # Code formatter
├── linter.ts          # Linter
├── errors.ts          # Error types & pretty printing
├── security.ts        # Security sandbox
├── repl.ts            # Interactive REPL
├── build.ts           # Build system & project scaffolding
├── package-manager.ts # Package manager
├── lsp.ts             # Language Server Protocol
└── version.ts         # Version info
```

## Development

```bash
# Install dependencies
npm install

# Build (TypeScript → JavaScript)
npm run build

# Run directly from source
npx tsx src/index.ts run ../examples/hello-world.arc

# Run with compiled output
node dist/index.js run ../examples/hello-world.arc
```

## CLI Commands

```bash
arc run <file>           # Execute an Arc file
arc repl                 # Interactive REPL
arc parse <file>         # Print AST
arc ir <file>            # Print IR
arc compile <file>       # Compile to JS (or --target=wat)
arc check <file>         # Semantic analysis
arc fmt <file>           # Format code (--write to overwrite)
arc lint <file>          # Lint code
arc builtins             # List all built-in functions
arc builtins --modules   # List stdlib modules
arc build                # Build project
arc test                 # Run project tests
arc new <name>           # Scaffold new project
arc version              # Print version
```

## Publishing

```bash
npm run copy-stdlib   # Copy stdlib into compiler package
npm run build         # Compile TypeScript
npm publish           # Publish to npm
```

The `prepublishOnly` script handles `copy-stdlib` and `build` automatically.

## See Also

- [Language documentation](../docs/)
- [Standard library](../stdlib/)
- [Examples](../examples/)
- [Architecture details](ARCHITECTURE.md)
- [Design decisions](DESIGN_DECISIONS.md)
