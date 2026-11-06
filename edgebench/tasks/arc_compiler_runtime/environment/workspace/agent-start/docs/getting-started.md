# Getting Started with Arc

> 🎮 **Want to try Arc without installing?** Use the [Online Playground](https://play.arclang.dev)!

## Installation

### Option A: Global Install (recommended)

```bash
npm install -g arc-lang
```

### Option B: From Source (for contributors)

```bash
# Source repository URL withheld in benchmark package
cd arc-lang/compiler
npm install
cd ..
```

**Requirements:** Node.js 18+ and npm.

### Editor Support

Install the [Arc extension for VS Code](https://marketplace.visualstudio.com/items?itemName=KaiBuildsAI.arc-lang) for syntax highlighting, diagnostics, hover info, go-to-definition, and completions. Search "Arc Language" in the Extensions panel.

## Your First Program

Create a file called `hello.arc`:

```arc
let name = "World"
print("Hello, {name}!")
```

Run it:

```bash
# If installed globally
arc run hello.arc

# If running from source
npx tsx compiler/src/index.ts run hello.arc
```

Output:
```
Hello, World!
```

## Using the REPL

Start an interactive session:

```bash
# If installed globally
arc repl

# If running from source
npx tsx compiler/src/index.ts repl
```

```
Arc REPL v0.1 — Type expressions to evaluate
> 2 + 3
5
> let x = 10
> x * 2
20
> [1, 2, 3] |> map(x => x * 2)
[2, 4, 6]
```

## Language Basics

### Variables

```arc
let name = "Arc"         # immutable (default)
let mut count = 0        # mutable (opt-in)
count = count + 1
```

### Functions

```arc
# Expression body (one-liners)
fn add(a, b) => a + b

# Block body
fn greet(name) {
  let msg = "Hello, {name}!"
  print(msg)
  msg
}
```

### Pipelines

Chain operations left-to-right instead of nesting:

```arc
# Instead of: sum(map(filter(data, ...), ...))
data |> filter(x => x > 0) |> map(x => x * 2) |> sum
```

### Pattern Matching

One construct for branching, destructuring, and type checking:

```arc
match value {
  0 => "zero",
  n if n < 0 => "negative",
  n => "positive: {n}"
}
```

### Collections

```arc
let list = [1, 2, 3, 4, 5]
let evens = [x for x in list if x % 2 == 0]

let map = {name: "Arc", version: 1}
```

### Tool Calls

First-class API calls — no imports, no setup:

```arc
let user = @GET "api/users/{id}"
@POST "api/messages" {text: "hello"}
```

## Next Steps

- **[Language Tour](language-tour.md)** — Complete walkthrough of every feature
- **[Learn Arc](../examples/learn/)** — Step-by-step examples (basics → async → modules)
- **[Standard Library Reference](stdlib-reference.md)** — Full stdlib API
- **[Examples](../examples/)** — Real-world programs with token comparisons
- **[FAQ](FAQ.md)** — Common questions answered
- **[Grammar Spec](../spec/grammar.md)** — Formal language specification
