# Arc FAQ

## Why another programming language?

Arc isn't for humans writing code in editors. It's for **AI agents generating and consuming code**. When you pay per token, syntax overhead matters. Arc eliminates the ceremony that traditional languages require — imports, async/await boilerplate, error handling scaffolding, API client setup — because AI agents don't need it.

## How is this different from Python or JavaScript?

| Aspect | Python/JS | Arc |
|--------|-----------|-----|
| API calls | Import library, create client, serialize, deserialize | `@GET "url"` — one line |
| Error handling | try/catch blocks | Map-based results with `if/el` |
| Async | async/await keywords everywhere | Auto-await by default |
| Data transformation | Method chains or nested calls | `\|>` pipeline operator |
| Pattern matching | if/elif/else chains (Python), switch (JS) | `match` with destructuring |
| Token cost | ~100 tokens for typical agent task | ~50 tokens for the same task |

Arc is a **domain-specific language** for AI agent workflows, not a general-purpose replacement.

## Can I use this in production?

Arc is in **active development** (Phase 6: Community & Adoption). The interpreter, compiler (with optimizer and JS/WAT codegen), 27 stdlib modules, LSP, VS Code extension, package manager, formatter, linter, and security sandbox are all working with 1,291+ tests passing. Follow the [roadmap](../ROADMAP.md) for status.

## How do tool calls work?

Tool calls use the `@` prefix to invoke external APIs and tools as first-class language constructs:

```arc
let user = @GET "api/users/123"              # HTTP GET
@POST "api/messages" {text: "hello"}          # HTTP POST with body
let answer = @llm("Summarize this: {text}")   # Custom tool
```

The runtime resolves `@GET`/`@POST` to HTTP calls and `@toolname` to registered tool handlers. No imports, no client initialization, no serialization code. The interpreter handles it.

## What's the token efficiency claim based on?

We measure using GPT-4's tokenizer (cl100k_base) across common agent programming patterns:

- **Function definitions:** ~50% fewer tokens than JS
- **API calls:** ~65% fewer tokens
- **Error handling:** ~75% fewer tokens
- **Pattern matching:** ~40% fewer tokens
- **Overall average across agent code:** ~53% reduction

See the [grammar spec](../spec/grammar.md#token-counting-methodology) for the full methodology and comparison table.

## What does `el` mean?

`el` is Arc's keyword for `else`. It saves 2 characters per use and is unambiguous in context:

```arc
let x = if ready { "go" } else { "wait" }
```

## How do I contribute?

See [CONTRIBUTING.md](../CONTRIBUTING.md). We welcome contributions from both AI agents and human developers.
