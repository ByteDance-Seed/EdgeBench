# Arc Examples

Practical, real-world programs showcasing Arc's expressiveness and token efficiency.

## Learn Arc

New to Arc? Start with the **[learn/](learn/)** subfolder — standalone examples covering basics, functions & pipelines, pattern matching, async & tools, and modules.

## Examples

| Example | Description | Key Features | Tokens vs JS |
|---------|-------------|-------------|-------------|
| [hello-world.arc](hello-world.arc) | Introduction to Arc basics | Variables, functions, pipelines, pattern matching | ~40% savings |
| [fizzbuzz.arc](fizzbuzz.arc) | Classic FizzBuzz, the Arc way | Pipelines, pattern matching, ranges, comprehensions | ~57% savings |
| [fibonacci.arc](fibonacci.arc) | Recursive, iterative, and memoized | Recursion, mutability, maps, pattern matching | ~45% savings |
| [calculator.arc](calculator.arc) | Expression tree calculator | Pattern matching, recursion, maps as tagged variants | ~50% savings |
| [todo-app.arc](todo-app.arc) | TODO list manager (add/remove/done/list) | Lists, mutability, maps, pipelines, string interpolation | ~48% savings |
| [word-counter.arc](word-counter.arc) | Word frequency analysis | Maps, pipelines, string ops, sorting, comprehensions | ~52% savings |
| [json-transformer.arc](json-transformer.arc) | Transform nested API data | Destructuring, nested maps, pipelines, comprehensions | ~55% savings |
| [sorting.arc](sorting.arc) | Quicksort, mergesort, insertion sort | Recursion, pattern matching, list ops, comprehensions | ~45% savings |
| [mini-agent.arc](mini-agent.arc) | AI agent: fetch, analyze, decide, act | **Tool calls, parallel fetch, pattern matching, pipelines** | **~54% savings** |

## Running Examples

```bash
# From the repo root
npx tsx compiler/src/index.ts run examples/hello-world.arc
npx tsx compiler/src/index.ts run examples/fizzbuzz.arc
```

## The Arc Advantage

The `mini-agent.arc` example is the flagship — it demonstrates why Arc exists. An AI agent that:
1. Fetches data from 3 APIs **in parallel** (one line)
2. Processes results with **pipelines and pattern matching**
3. Makes decisions based on combined data
4. Composes and delivers a briefing

In JavaScript, this requires ~120 tokens with imports, async/await ceremony, Promise.all, manual JSON parsing, and error handling. In Arc: ~55 tokens. That's real savings at scale.

## Contributing

Add examples that demonstrate measurable efficiency gains. Each example should include:
- A comment header explaining what it demonstrates
- Token comparison comments where relevant
- Clean, idiomatic Arc code
