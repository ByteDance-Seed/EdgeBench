# API Testing Framework Enhancement Plan

## Overview

This library is a property-based testing framework for validating HTTP APIs against their OpenAPI and GraphQL specifications. It generates diverse test cases from schema definitions and validates responses, helping developers find bugs through intelligent fuzzing and coverage analysis.

---

## Goals

We plan to strengthen the framework's data generation and validation pipelines. The core theme of this iteration is **structured awareness**: rather than treating all header parameters as opaque strings and all schema compositions as flat unions, the framework should leverage protocol-level grammar knowledge and schema metadata to produce smarter test data and catch more subtle conformance violations.

Specifically, we are introducing structured generation strategies for well-known HTTP headers (`If-Match`, `Range`, etc.) so the framework can produce protocol-valid values that exercise real server behavior. In parallel, we are making the `discriminator` keyword a first-class citizen in both directions: during generation (pinning the discriminator property to valid values) and during validation (rejecting responses whose discriminator value doesn't match any known schema).

Several independent improvements round out this release: extending `filter_case`/`map_case` hooks to the coverage phase so users' customizations apply uniformly; adding a `schemathesis.pytest.parametrize()` helper for testing multiple schemas in a single function; reporting all distinct JSON Schema errors per response rather than stopping at the first; fixing pattern quantifier transforms for multi-character groups; and making schema loading retry on HTTP 503.

The following capabilities are planned for this release:

- **Target 1: Structured header generation strategies** — Generate protocol-conformant values for conditional and range headers instead of random strings
- **Target 2: Coverage phase hook support** — Apply `filter_case` and `map_case` hooks during the coverage phase, not just the fuzzing phase
- **Target 3: Multi-schema pytest parametrize** — Allow testing multiple named schemas in a single test function via `schemathesis.pytest.parametrize()`
- **Target 4: Discriminator response validation** — Validate that discriminator property values in responses match known schema mappings
- **Target 5: Discriminator-aware data generation** — Pin the discriminator property to correct values when generating data for `oneOf`/`anyOf` schemas
- **Target 6: Schema loading 503 retry** — Make `--wait-for-schema` retry on HTTP 503 Service Unavailable responses
- **Target 7: Report all distinct schema errors** — Report every distinct JSON Schema validation error per response, not just the first
- **Target 8: Pattern quantifier transform fix** — Correctly handle multi-character repeated groups when adjusting regex quantifiers for length constraints

---

## Target 1: Structured Header Generation Strategies

HTTP headers like `If-Match`, `If-Modified-Since`, and `Range` have well-defined grammars (RFC 7232, RFC 7233). Currently, when a schema declares a header parameter with `type: string` and no format, the framework generates arbitrary header-safe strings. This means servers rarely see structurally valid conditional or range requests during testing, missing bugs in range handling and cache invalidation logic.

We plan to add a dedicated header strategies module that provides Hypothesis strategies producing grammatically correct values for these headers. When the framework encounters a known header name in a parameter definition, it should use the appropriate structured strategy instead of the generic header format.

In positive generation mode, all generated values should conform to the protocol grammar. In negative mode, the strategy should produce a mix of valid values, slightly-invalid values (e.g., inverted byte ranges), and completely random values to test error handling.

### Requirements

1. **Header format registry**: Maintain a mapping from lowercase header names to internal format keys. Recognize `if-match`, `if-none-match` (ETag-list), `if-modified-since`, `if-unmodified-since` (HTTP-date), and `range`.

2. **ETag-list strategy**: Generate valid ETag header values including wildcard, strong ETags, weak ETags, and comma-separated lists.

3. **HTTP-date strategy**: Generate valid HTTP-date values in IMF-fixdate format.

4. **Range strategy**: Generate valid `Range` header values using byte ranges including int-ranges (first <= last), suffix-ranges, and open-ended ranges. May produce multi-range specifications.

5. **Slightly-invalid range strategy**: Generate near-valid Range values that violate the spec in specific ways: inverted bounds, negative positions, wrong unit names, and empty range sets.

6. **Mode-aware strategy dispatch**: Return appropriate strategies based on the generation mode. In positive mode, return only grammatically valid strategies. In negative mode, blend valid, slightly-invalid, and random values.

7. **Integration with parameter generation**: When a header parameter has `type: string` with no explicit format and its name matches a known header, assign the corresponding structured format key instead of the generic header format.

---

## Target 2: Coverage Phase Hook Support

The `filter_case` and `map_case` hooks allow users to customize generated test cases — filtering out unwanted cases or transforming them before execution. Currently these hooks are applied during the hypothesis-driven fuzzing phase but are skipped during the coverage phase (which generates deterministic edge-case scenarios). This means users who rely on hooks to, for example, inject authentication tokens or filter out certain paths get inconsistent behavior across phases.

We plan to apply both `filter_case` and `map_case` hooks from all dispatcher levels (global, schema, per-test) during coverage case generation, so that user customizations are respected uniformly.

### Requirements

1. **`filter_case` in coverage phase**: After generating each coverage case, apply all registered `filter_case` hooks (from global, schema-level, and per-test dispatchers). If any hook returns `False`, skip that case entirely.

2. **`map_case` in coverage phase**: After filter hooks pass, apply all registered `map_case` hooks. Each hook receives the case and returns a (possibly modified) case that replaces the original.

3. **Dispatcher ordering**: Process hooks from all dispatchers (global → schema → per-test), checking each hook's applicability via the existing skip-hook logic.

---

## Target 3: Multi-Schema Pytest Parametrize

When testing a microservices architecture, developers often want to run the same validation logic against multiple API schemas. Currently, each schema requires its own decorated test function. This leads to duplicated code when the test body is identical across schemas.

We plan to add `schemathesis.pytest.parametrize()` — a decorator that accepts multiple named schemas as keyword arguments and generates test items for each schema's operations, prefixed with the schema name. Additionally, `schema.parametrize()` should support reuse: the same base function can be decorated by different schemas' `parametrize()` calls and assigned to distinct names without conflict.

### Requirements

1. **`schemathesis.pytest.parametrize`**: Accepts keyword arguments where each key is a schema name and each value is a schema instance. Returns a decorator. Both sync and async test functions must be supported.

2. **Test item naming**: Each generated test item should include the schema name as an additional bracketed prefix before the operation label.

3. **Schema reuse via `parametrize()`**: The same base test function should be reusable with multiple schemas by assigning to different names. Each assignment should produce independent test items without conflict.

---

## Target 4: Discriminator Response Validation

OpenAPI's `discriminator` keyword indicates which schema in a `oneOf`/`anyOf` composition applies to a given response object, based on a property value. Currently, `response_schema_conformance` validates the response against the composed schema but does not check whether the discriminator property value actually corresponds to a known schema name or explicit mapping entry.

We plan to add a discriminator value check: after standard schema validation passes, inspect the discriminator configuration and verify that the property value in the response matches either an explicit mapping key or an implicit schema name derived from `$ref` paths.

### Requirements

1. **Discriminator value validation**: In `response_schema_conformance`, after standard JSON Schema validation, check if the response schema has a `discriminator` with a `propertyName`. If the response body contains that property, verify its value is in the set of known values.

2. **Known values set construction**: Known values include all keys from explicit mapping plus all schema names extracted from `$ref` paths in `anyOf`/`oneOf` items (implicit). Both sources always apply.

3. **Skip conditions**: Skip the check if there is no `propertyName`, or if the response body does not contain the discriminator property.

4. **Failure reporting**: When validation fails, raise a failure indicating the discriminator value does not match any known schema mapping.

---

## Target 5: Discriminator-Aware Data Generation

When generating request data for schemas with `discriminator`, the framework currently produces random values for the discriminator property, leading to invalid requests that get rejected before reaching meaningful application logic. By pinning the discriminator property to its correct value for each branch, generated data will always carry the appropriate type tag.

We plan to inject `const` constraints into `oneOf`/`anyOf` branches during the JSON Schema conversion step, so that `hypothesis-jsonschema` naturally generates the correct discriminator value for whichever branch it selects.

### Requirements

1. **Const injection during conversion**: In `to_json_schema`, when a schema has a `discriminator` with `propertyName` and `oneOf`/`anyOf` items that are `$ref` objects, wrap each item in `allOf` with a `const` constraint on the discriminator property.

2. **Value resolution**: For explicit mapping, use the mapping entries reversed to find the discriminator value for each ref. For implicit mapping, extract the schema name from the last path segment of the `$ref`.

3. **Bundled ref handling**: When refs have been bundled (prefixed with a storage path), resolve them back to their original URI before extracting the schema name.

4. **Non-request schemas excluded**: Only inject const constraints for request schemas, controlled by the `is_response_schema` flag.

---

## Target 6: Schema Loading 503 Retry

When using `--wait-for-schema` to wait for an API to become available during startup, the framework currently only retries on connection errors. If the server is up but returning 503 Service Unavailable (common during initialization), loading fails immediately rather than retrying.

We plan to treat HTTP 503 as a retryable condition within the `wait_for_schema` timeout window.

### Requirements

1. **503 retry behavior**: When `wait_for_schema` is set, HTTP 503 responses should trigger a retry (same interval and timeout as connection errors).

2. **Exhausted retries**: If retries are exhausted while still receiving 503, raise a `LoaderError` indicating the server returned 503.

---

## Target 7: Report All Distinct Schema Errors

Currently, `response_schema_conformance` stops at the first JSON Schema validation error. When a response violates multiple independent constraints, only one gets reported per test run.

We plan to collect all distinct validation errors and report them together. The same applies to response header conformance checks.

### Requirements

1. **Body schema validation**: Use iterative error collection instead of single-error validation. Deduplicate failures before reporting.

2. **Header validation**: Similarly collect all header schema violations per header rather than stopping at the first.

---

## Target 8: Pattern Quantifier Transform Fix

The framework transforms regex patterns with length constraints (minLength/maxLength) by adjusting quantifiers. The current implementation incorrectly wraps single character classes in unnecessary groups when they already have a natural repetition point.

This fix requires a rewrite of the pattern transformation logic to properly handle the sre_parse AST, including support for lookahead/lookbehind assertions, possessive quantifiers, and multi-character group inner lengths.

### Requirements

1. **Character class quantifier**: When the pattern body is a single character class, apply the quantifier directly to it without wrapping in a group.

2. **Lookahead/lookbehind support**: The transform must handle patterns containing assertions without corrupting them.

3. **Multi-character group inner length**: When computing the repetition count for a group containing multiple characters, account for the group's inner length rather than treating it as length 1.

4. **Serialization roundtrip**: The rewritten transform must serialize the modified AST back to a valid Python regex string that compiles without error.

---

## Completion Criteria

- All new modules importable from their documented paths
- Existing APIs remain backward-compatible
- Header strategies produce values matching protocol grammars
- Coverage phase respects user hooks uniformly
- Discriminator handling is consistent between generation and validation
- Pattern transforms produce correct quantified patterns without unnecessary groups
