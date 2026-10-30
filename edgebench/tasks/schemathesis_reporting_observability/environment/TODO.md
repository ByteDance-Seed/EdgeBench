# API Testing Framework Validation & Reporting Enhancement Plan

## Overview

This library is a property-based testing framework for OpenAPI and GraphQL APIs. It generates test cases from API schemas and validates responses against specifications. Its architecture is progressively expanding from pure validation into comprehensive test reporting and observability.

---

## Goals

Our primary goal this release is to build a unified reporting infrastructure that captures HTTP interactions (requests, responses, and validation outcomes) and writes them to multiple output formats (VCR cassettes, HAR archives, JUnit XML). This requires a new post-validation hook that fires after all checks run on a response, providing structured check results that report writers can consume.

In parallel, the examples generation phase needs enhancement: currently it only generates values for required properties that have explicit examples, but we plan to also generate values for optional properties (using schema-based generation when no example is available) and produce one disjoint example set per `oneOf`/`anyOf` branch rather than merging branches together.

Additionally, two targeted fixes are needed: the `format: email` strategy generates domain names that fail `jsonschema_rs` validation, and the `allow-extra-parameters = false` configuration does not suppress unexpected properties in request bodies (only query/header/cookie).

The following capabilities are planned for this release:

- **Target 1: Post-Validation Hook System** — A new hook that fires after response validation, carrying structured check outcomes
- **Target 2: Reporting Writers Module** — A new `reporting` package providing VCR, HAR, JUnit XML, and NDJSON writer classes
- **Target 3: Pytest Plugin Report Integration** — Connect the reporting writers to the pytest plugin via schema-level hooks and config
- **Target 4: Examples Phase Enhancement** — Generate optional properties and produce per-branch example sets for `oneOf`/`anyOf`
- **Target 5: Email Format & Coverage Fixes** — Fix email format strategy and extend body parameter coverage control

---

## Target 1: Post-Validation Hook System

The framework's hook system currently lacks visibility into validation outcomes. When checks run on a response, hooks like `after_call` fire before validation happens, so there's no way for external code (report writers, custom loggers) to observe which checks passed or failed on each response.

We need a new `after_validate` hook that fires after all validation checks complete, carrying a list of structured result objects. This hook must support both global and schema-level registration. Additionally, flatmap hooks currently raise `RuntimeError` in negative testing mode because the wrapper doesn't handle `GeneratedValue` objects for strategies (only for plain values).

### Requirements

1. **`CheckResult` dataclass**: A new dataclass exported from the top-level package that represents the outcome of a single validation check. It carries the check name, a status (using the existing `Status` enum from `schemathesis.engine`), and an optional failure object.

2. **`after_validate` hook specification**: A new hook that fires after all validation checks complete. It must be available at all scopes (global, schema, test). When registered, `validate_response` must collect per-check outcomes and dispatch them. When no listener is registered, the existing code path should remain unchanged for performance.

3. **`after_network_error` hook specification**: A new hook that fires when a network-level error occurs during request execution. Available at global and schema scope.

4. **Schema-level dispatch for `after_call`**: The existing `after_call` hook must also dispatch on the schema-level hook dispatcher (not only globally), so schema-specific listeners receive it.

5. **`HookDispatcher.defines` method**: Returns whether any hooks are registered under a given name. Used to conditionally enable result collection only when `after_validate` listeners exist.

6. **Flatmap hook wrapper for negative mode**: The flatmap hook wrapper must handle `GeneratedValue` inputs by unwrapping, calling the hook, then re-wrapping results to preserve metadata through the flatmap chain.

---

## Target 2: Reporting Writers Module

The framework currently has reporting logic embedded in the CLI handler layer. We need to extract and unify it into a standalone `reporting` package that provides writer classes for VCR, HAR, JUnit XML, and NDJSON formats. These writers accept `ScenarioRecorder` objects and produce formatted output.

### Requirements

1. **`schemathesis.reporting` package**: A new package that exports `VcrWriter`, `HarWriter`, `JunitXmlWriter`, `NdjsonWriter`, and `get_command_representation`.

2. **`VcrWriter`**: A context-manager class that writes VCR YAML cassette files. Methods: `open` (writes header with seed and command), `write` (writes interactions from a recorder).

3. **`HarWriter`**: A context-manager class that writes HAR JSON files. Methods: `open`, `write`.

4. **`JunitXmlWriter`**: A context-manager class that writes JUnit XML reports. Methods: `open`, `write` (accepts recorder and elapsed time), `record_error` (records a test error).

5. **`NdjsonWriter`**: A context-manager class that writes newline-delimited JSON event streams. Methods: `open` (writes initialization event), `write` (writes test events).

6. **`ReportFormat.ALLURE` enum member**: Add an `ALLURE` member to the `ReportFormat` enum for directory-based output.

7. **`ReportsConfig` updates**: Add allure support and a method for getting stable (timestamp-free) paths for cross-process transport.

---

## Target 3: Pytest Plugin Report Integration

The reporting writers from Target 2 need to be wired into the pytest plugin so that users can configure report generation via the schema's config. This requires a dispatcher class that registers hooks on a schema and accumulates interaction data, plus pytest-xdist support for distributed workers.

### Requirements

1. **`PytestReportDispatcher` class** in `schemathesis.pytest.reporting`: Registers hook handlers on a schema's hook dispatcher. Accumulates `ScenarioRecorder` instances keyed by operation label. Provides methods to retrieve and remove a recorder, and to unregister all hooks.

2. **Pytest plugin integration**: When a schema has reports configured, the plugin must open writers at session start, feed recorders to writers at test teardown, and close writers at session finish. Must handle both stateful and stateless test modes.

3. **Stateful test support**: When running via the state machine, the TestCase class must support a callback mechanism that connects the state machine's recorder to the report writers.

4. **`pytest-xdist` support module** (`schemathesis.pytest.xdist`): Workers serialize interaction data via `workeroutput`; the controller deserializes and writes to report files. Must handle multiple schemas, stable file paths, and graceful cleanup on writer failures.

---

## Target 4: Examples Phase Enhancement

The examples extraction phase currently only generates example values for required properties that have explicit `example`/`examples` annotations. Optional properties without examples are silently skipped, reducing test coverage. Additionally, when a schema uses `oneOf`/`anyOf`, all branches are merged into a single combined set rather than producing distinct examples per branch.

After this change: (1) all properties (required and optional) that have at least one sibling with an explicit example will get generated values, and (2) `oneOf`/`anyOf` schemas produce one disjoint example set per branch, with each set containing only the properties relevant to that branch.

### Requirements

1. **`_yield_examples_from_properties` function**: Generates example values for all properties (not just required ones). When at least one property has an explicit example, generates values for properties without examples using schema-based generation.

2. **`_yield_examples_per_branch` function**: For schemas with `oneOf`/`anyOf`, identifies which properties are claimed by each branch. For each branch, assembles an active property set combining parent properties not claimed by other branches plus branch-specific properties. Delegates to `_yield_examples_from_properties` for each branch's active set.

3. **`extract_from_schema` refactoring**: The main extraction function detects top-level `oneOf`/`anyOf` and delegates to per-branch generation when branches exist. The old required-field gating logic is removed — generation is now triggered by any property having an explicit example.

---

## Target 5: Email Format & Coverage Fixes

Two independent fixes in the generation layer:

1. The `format: email` strategy generates email addresses where the domain part has mixed-case ACE prefixes which fail validation per RFC 3490. Since email domains are case-insensitive per RFC 5321, the fix is to lowercase the domain part of generated emails.

2. The `allow-extra-parameters = false` configuration suppresses unexpected-properties coverage scenarios for query, header, and cookie parameters, but not for request bodies. Bodies should be included in this suppression.

### Requirements

1. **Email format strategy**: Add a helper that lowercases the domain part of an email address. Register strategies for both email and idn-email formats using this helper.

2. **Body parameter coverage control**: In the coverage generation logic that skips unexpected-properties scenarios when extra parameters are disallowed, include body parameters alongside the existing query, header, and cookie locations.

---

## Public API and Edge-Case Clarifications

- `CheckResult` should be importable from both `schemathesis.checks` and the top-level `schemathesis` package.
- Reporting writers are public under `schemathesis.reporting`. `NdjsonWriter`, `JunitXmlWriter`, `VcrWriter`, and `HarWriter` should support the tested keyword constructors such as `output=...` and, for VCR/HAR, `config=...`.
- `ReportsConfig.update(allure_path=...)` enables the Allure report target, and `ReportsConfig.get_stable_path(format, suffix=...)` should return timestamp-free paths suitable for xdist handoff. `ReportFormat.ALLURE.extension` is an empty string.
- For examples generation, branch-local property isolation applies even when branch requirements refer to properties declared in the parent object. A property required by a branch belongs in that branch's generated example; if another branch requires the same property plus an additional property, the first branch should not inherit the additional sibling property.
- `oneOf` and `anyOf` branches should produce one example set per active branch. Parent properties with explicit examples remain shared base properties; branch-claimed properties are added only to the relevant branch example.

## Phase Granularity Note

- Phase 4 can be almost complete while still failing if one branch-isolation edge case is wrong; phases 1-3 cover broader hook/reporting/pytest integration surfaces and need their public import paths plus runtime behavior implemented together.

---

## Completion Criteria

- `CheckResult` importable from `schemathesis` top-level
- `after_validate` hook fires with correct results for both passing and failing checks at global and schema scope
- `schemathesis.reporting` package exports all four writer classes
- `PytestReportDispatcher` correctly accumulates recorder data via hooks
- Examples phase produces optional property values and per-branch disjoint sets
- Email format generates only lowercase-domain addresses
- `allow-extra-parameters = false` suppresses body unexpected properties
- Existing APIs remain unchanged (backward compatibility)
