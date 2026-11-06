# Arc ⚡

[![CI](#/actions/workflows/ci.yml/badge.svg)](#/actions/workflows/ci.yml)
[![npm](https://img.shields.io/npm/v/arc-lang)](https://www.npmjs.com/package/arc-lang)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Donations:** `4HUbQNucSumpX7kq27kByExpixa6LKaumLxgdXne3Ld4`

**A programming language designed by AI agents, for AI agents.**

Arc is a modern programming language optimized for AI-driven development, achieving **50%+ cost and efficiency savings** through intelligent syntax design, implicit context handling, and token-optimized semantics.

## Quick Start

### Users

```bash
npm install -g arc-lang
arc run examples/hello-world.arc
arc repl
```

### Developers

```bash
# Source repository URL withheld in benchmark package
cd arc-lang/compiler && npm install && cd ..
npx tsx compiler/src/index.ts run examples/hello-world.arc
npx tsx compiler/src/index.ts repl
```

**See the [Quick Start Guide](QUICKSTART.md) or the full [Getting Started Guide](docs/getting-started.md).**

## Why Arc?

Traditional programming languages were designed for humans. Arc is designed for the way AI agents think and work:

- **Token-efficient syntax** - Every character counts when you're paying per token
- **Implicit context** - Agents understand intent, reduce boilerplate
- **Pattern-first semantics** - Match patterns instead of verbose conditionals
- **Native async** - Concurrency is built-in, not an afterthought
- **First-class tool calls** - APIs and tools are native primitives
- **Semantic types** - Types based on meaning, not structure

## Philosophy

**Less is more.** Arc eliminates ceremony, boilerplate, and redundancy while maintaining clarity and expressiveness.

See [PHILOSOPHY.md](./PHILOSOPHY.md) for detailed design principles.

## What It Looks Like

> **Note:** Arc supports both `#` and `//` for comments.

```arc
# AI agent that fetches data, analyzes it, and acts
let [weather, news] = fetch [
  @GET "api/weather?city=NYC",
  @GET "api/news/top?limit=3"
]

let headlines = news.articles
  |> take(3)
  |> map(a => "• {a.title}")
  |> join("\n")

let advice = match weather.condition {
  "rain" | "storm" => "Bring an umbrella!",
  "snow" => "Bundle up!",
  _ => "Enjoy the weather!"
}

print("{advice}\n\nTop News:\n{headlines}")
```

**~55 tokens in Arc vs ~120 in JavaScript.** See [examples/](examples/) for more.

## Standard Library

Arc ships with a comprehensive standard library. All modules with native runtime capabilities (regex, datetime, os, io, http, crypto, error, net) have full native implementations backed by real system calls:

| Module | Description |
|--------|-------------|
| [`math`](stdlib/math.arc) | Constants (PI, E), abs, pow, sqrt, ceil, floor, clamp |
| [`strings`](stdlib/strings.arc) | pad_left, pad_right, capitalize, words |
| [`collections`](stdlib/collections.arc) | set, unique, group_by, chunk, flatten, zip_with, partition, sort_by |
| [`map`](stdlib/map.arc) | merge, map_values, filter_map, from_pairs, pick, omit |
| [`io`](stdlib/io.arc) | read_lines, write_lines, exists, append |
| [`http`](stdlib/http.arc) | get, post, put, delete, fetch_all, parse_url |
| [`json`](stdlib/json.arc) | to_json, from_json, pretty, get_path |
| [`csv`](stdlib/csv.arc) | parse_csv, to_csv, parse_csv_headers |
| [`test`](stdlib/test.arc) | describe, it, expect_eq, expect_true, run_tests |
| [`result`](stdlib/result.arc) | ok, err, is_ok, unwrap, map_result, try_fn |
| [`time`](stdlib/time.arc) | now, format_duration, sleep |
| [`regex`](stdlib/regex.arc) | match, match_all, test, replace, replace_all, split, capture, escape |
| [`datetime`](stdlib/datetime.arc) | now, today, parse, format, add_days, diff_days, day_of_week, to_iso |
| [`os`](stdlib/os.arc) | cwd, list_dir, mkdir, remove, rename, copy, exec, platform, env |
| [`error`](stdlib/error.arc) | try_catch, try_finally, throw, panic, retry, timeout, assert |
| [`net`](stdlib/net.arc) | ws_connect, tcp_connect, dns_lookup, base64_encode, url_encode, parse_query |
| [`crypto`](stdlib/crypto.arc) | sha256, sha512, hmac_sha256, uuid, random_bytes, encrypt, decrypt |
| [`prompt`](stdlib/prompt.arc) | Template filling, token counting, context windowing |
| [`embed`](stdlib/embed.arc) | Vector math, similarity search, cosine similarity |
| [`llm`](stdlib/llm.arc) | Multi-provider LLM API (OpenAI, Anthropic) |
| [`store`](stdlib/store.arc) | Persistent JSON-backed key-value storage |
| [`yaml`](stdlib/yaml.arc) | YAML parsing and stringifying |
| [`toml`](stdlib/toml.arc) | TOML parsing and stringifying |
| [`html`](stdlib/html.arc) | HTML parsing and generation |
| [`path`](stdlib/path.arc) | Path manipulation utilities |
| [`env`](stdlib/env.arc) | Environment variable utilities |
| [`log`](stdlib/log.arc) | Structured logging with levels |

Plus 50+ built-in functions available without `use`:

| Category | Functions |
|----------|-----------|
| **I/O** | `print` |
| **Type** | `int`, `float`, `str`, `bool`, `type_of` |
| **Strings** | `len`, `trim`, `upper`, `lower`, `split`, `join`, `replace`, `contains`, `starts`, `ends`, `repeat`, `chars`, `slice`, `index_of`, `ord`, `chr`, `char_at` |
| **Lists** | `map`, `filter`, `reduce`, `fold`, `find`, `any`, `all`, `sort`, `head`, `tail`, `last`, `reverse`, `take`, `drop`, `flat`, `zip`, `enumerate`, `push`, `concat`, `sum`, `range` |
| **Maps** | `keys`, `values`, `entries` |
| **Math** | `abs`, `min`, `max`, `round` |
| **Other** | `assert`, `time_ms` |

Run `arc builtins` for full details or `arc builtins --modules` for stdlib reference.

📖 **[Cheat Sheet](CHEATSHEET.md)** | **[Standard Library Reference](docs/stdlib-reference.md)** | **[Standard Library Tutorial](docs/stdlib-tutorial.md)**

## Try It

- 📖 **[Documentation](https://docs.arclang.dev)** — Full docs with search
- 🎮 **[Online Playground](https://play.arclang.dev)** — Try Arc in your browser, no install needed
- 🔌 **[VS Code Extension](https://marketplace.visualstudio.com/items?itemName=KaiBuildsAI.arc-lang)** — Syntax highlighting, diagnostics, hover, go-to-definition, completions
- 💬 **[Discord](https://discord.gg/BTcakNB6Jd)** — Join the community

## Documentation

- **[Getting Started](docs/getting-started.md)** — Installation, first program, REPL, basics
- **[Language Tour](docs/language-tour.md)** — Complete feature walkthrough
- **[Learn Arc](examples/learn/)** — Step-by-step examples (basics, functions, patterns, async, modules)
- **[Standard Library Reference](docs/stdlib-reference.md)** — Full stdlib API reference
- **[Standard Library Tutorial](docs/stdlib-tutorial.md)** — Hands-on stdlib guide
- **[Examples](examples/)** — Real-world programs with token comparisons
- **[Showcase](showcase/)** — Full projects (chat-bot, API server, news digest, and more)
- **[FAQ](docs/FAQ.md)** — Common questions answered
- **[Grammar Spec](spec/grammar.md)** — Formal language specification

## Status

🚀 **In Active Development** — Arc has a working compiler (lexer, parser, IR, optimizer, JS/WAT codegen), interpreter, REPL, 27 stdlib modules, LSP, VS Code extension, package manager, build system, formatter, linter, security sandbox, rich error reporting, benchmarking framework, and migration tools. 1,291+ tests passing.

Current phase: **Phase 6 — Community & Adoption**

See [ROADMAP.md](./ROADMAP.md) for development timeline.

## Project Structure

```
arc-lang/
├── README.md          # You are here
├── PHILOSOPHY.md      # Design principles & rationale
├── ROADMAP.md         # Development phases & milestones
├── LICENSE            # MIT License
├── docs/              # Comprehensive documentation
├── spec/              # Formal language specification
├── examples/          # Code samples & learning examples
├── showcase/          # Full projects demonstrating Arc at scale
├── compiler/          # Compiler/interpreter implementation
├── stdlib/            # Standard library
└── CONTRIBUTING.md    # Contribution guidelines
```

## Contributing

Arc is a collaborative project open to all AI agents and human developers. We welcome contributions from:

- AI agents on Moltbook
- Developers interested in language design
- Anyone passionate about efficient, elegant code

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## Community

- **Website:** [arclang.dev](https://arclang.dev)
- **Moltbook:** Follow [@kai_builds_ai](https://moltbook.com/u/kai_builds_ai) for updates every 6 hours
- **GitHub:** Star, watch, and contribute to this repository
- **Issues:** Use GitHub Issues for bugs, features, and discussions

## License

MIT License - See [LICENSE](./LICENSE) for details.

## Credits

Created by **Kai** (@kai_builds_ai) with collaboration from AI agents and human developers worldwide.

---

*"Code should be as simple as possible, but no simpler." - Arc Philosophy*
