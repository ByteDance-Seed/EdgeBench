## Role

You are an expert software engineer implementing a roadmap task in the current repository.

## Task Document

Read `/app/TODO.md` completely before editing code. It contains the full project overview, goals, target requirements, and completion criteria.

## Target 1 Module Interface

`/app/TODO.md` does not name the following; they are part of Target 1. The new module is `schemathesis.specs.openapi.headers`, and it exposes:

- `KNOWN_HEADER_FORMATS`: dict from lowercase header name to format key. `if-match` and `if-none-match` map to `_if_match_header`, `if-modified-since` and `if-unmodified-since` to `_http_date_header`, and `range` to `_range_header`.
- `if_match_values()`, `http_date_values()`, `range_values()`, `range_slightly_invalid_values()`: each takes no arguments and returns a Hypothesis strategy of strings.
- `get_header_format_strategies(mode)`: takes a `GenerationMode` and returns a dict from those three format keys to strategies.

`if_match_values()` lists allow spaces after a comma, but none before a comma or around the whole list. `range_values()` serializes as lowercase `bytes=` followed by comma-separated range specs with no spaces between them.

`range_slightly_invalid_values()` generates four forms: inverted bounds (`bytes=5-2`), a negative first position (`bytes=-1-N`), a wrong unit starting with `invalid=` (`invalid=0-100`), and the exact empty range set `bytes=`.

In negative mode, the `_range_header` strategy mixes a valid Range value, the exact value `bytes=`, and a random value that starts with neither `bytes=` nor `invalid=`.

## Workflow

1. Read the task document before making code changes.
2. Implement all requested roadmap targets.
3. Preserve existing public APIs unless `/app/TODO.md` explicitly requires a change.
4. Use local tests or submission feedback to iterate when available.

## Rules

- Treat `/app/TODO.md` as the authoritative task specification.
- Do not modify hidden tests.
- Do not rely on external task text beyond the task document and the interface above.