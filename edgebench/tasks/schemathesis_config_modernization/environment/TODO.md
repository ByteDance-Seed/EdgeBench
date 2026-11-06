# API Testing Framework Architecture Modernization

## Overview

This library is a property-based testing framework for validating HTTP APIs against their OpenAPI or GraphQL schemas. It generates test cases from schema definitions and validates that API implementations conform to their contracts. The framework is evolving toward a cleaner, more modular architecture with centralized configuration and well-separated concerns.

---

## Goals

We plan to introduce a comprehensive configuration system backed by TOML files, replacing the scattered command-line flags and programmatic configuration that has grown unwieldy. The configuration system will support auto-discovery, environment variable substitution, schema validation with helpful error messages, and per-operation overrides through a phase-based testing model (examples, fuzzing, coverage, stateful).

Alongside the configuration system, the public Python API requires significant reorganization. Schema loaders will move into spec-specific namespaces, the "targets" concept will be renamed to "metrics" with a proper context object, the check registration system will gain a richer context, and the transport/serialization layer will be rebuilt around a `BaseTransport` abstraction with a unified `Response` class that normalizes different HTTP client implementations.

The following capabilities are planned for this release:

- **Target 1: Configuration System** — Centralized TOML-based configuration with discovery, validation, and environment variable substitution
- **Target 2: API Namespace Reorganization** — Schema loaders moved to spec-specific namespaces, public API cleaned up
- **Target 3: Metric System** — Renamed from "targets" to "metrics" with proper context and collector abstractions
- **Target 4: Transport & Serialization** — New base transport abstraction with unified serializer registration
- **Target 5: Response Class** — Unified response wrapper normalizing requests/httpx/werkzeug responses
- **Target 6: Check System** — Redesigned check registration with rich context and configuration access

---

## Target 1: Configuration System

The framework currently relies on a large number of CLI flags and programmatic API calls for configuration. We plan to introduce a TOML-based configuration file that centralizes all settings with auto-discovery, validation, and environment variable substitution.

The configuration system should discover config files by searching upward from the current directory, stopping at filesystem root or a `.git` directory. It should parse TOML content, validate against a JSON schema (producing user-friendly error messages), and support environment variable substitution in string values.

### Requirements

1. **`SchemathesisConfig` class** in `schemathesis.config`: A dataclass-based configuration container with top-level fields for color, health check suppression, seed, wait-for-schema timeout, max failures, reports config, output config, and projects config.

2. **Discovery mechanism** via `SchemathesisConfig.discover()` classmethod: Search for the config file starting from the working directory, walking parent directories. Stop when a `.git` directory is found or filesystem root is reached. Return default config if no file found.

3. **Loading methods**: `from_path`, `from_str`, and `from_dict` forming a delegation chain from file reading through TOML parsing to schema validation and config construction.

4. **`ConfigError`** class (subclass of the framework's base error) with a `from_validation_error` classmethod that formats jsonschema `ValidationError` into human-readable messages. The formatter should handle enum errors (with closest-match suggestions), minimum value errors, required property errors, type errors, and additionalProperties errors.

5. **Environment variable substitution** via a `resolve` function: Substitutes environment variables in string values. Raises `ConfigError` for invalid placeholders or missing variables.

6. **`PhasesConfig`** containing four phase configs: `ExamplesPhaseConfig`, `CoveragePhaseConfig`, `PhaseConfig` (for fuzzing), and `StatefulPhaseConfig`. Each phase has enabled, generation, and checks sub-configs. The `PhasesConfig` should support lookup by name and an update method that enables/disables phases by name list.

7. **`GenerationConfig`**: Contains settings for generation modes, examples count, shrinking, determinism, character restrictions, metrics maximization, security parameters, and other generation options. Should have a `from_dict` classmethod that parses kebab-case keys from config dictionaries.

---

## Target 2: API Namespace Reorganization

The current top-level API has grown cluttered with many loader functions and backward-compatibility aliases. We plan to reorganize by moving schema loaders into spec-specific namespaces and cleaning up the top-level exports.

### Requirements

1. **OpenAPI loaders namespace** (`schemathesis.openapi`): Must expose `from_url`, `from_dict`, `from_wsgi`, `from_asgi`, `from_file`, `from_path`. Also expose `format` (for string format registration) and `media_type`.

2. **Pytest namespace** (`schemathesis.pytest`): Must expose `from_fixture`.

3. **Top-level public API** (`schemathesis`): Must export `Case`, `Response`, `APIOperation`, `BaseSchema`, `Config` (alias for `SchemathesisConfig`), `GenerationMode`, `stateful`, `errors`, `openapi`, `graphql`, `pytest`, `hook`, `HookContext`, `check`, `CheckContext`, `CheckFunction`, `auth`, `AuthContext`, `AuthProvider`, `metric`, `MetricContext`, `MetricFunction`, `serializer`, `SerializationContext`, `__version__`.

4. **`GenerationMode` enum** (replacing `DataGenerationMethod`): String enum with members for positive and negative generation, with convenience boolean properties.

---

## Target 3: Metric System

The current "targets" system for targeted property-based testing uses a simple function registration pattern. We plan to rename it to "metrics" with a proper context object that bundles the test case and response, a collector abstraction for aggregation, and a cleaner registration decorator.

### Requirements

1. **`MetricContext` dataclass** with `__slots__`: Carries the `case` and `response` for metric evaluation.

2. **`MetricFunction`** type alias: A callable that takes a `MetricContext` and returns a float.

3. **`@schemathesis.metric` decorator**: Registers a metric function into a registry. Returns the function unchanged.

4. **Built-in `response_time` metric**: Registered via the decorator, returns the response elapsed time.

5. **`MetricCollector` class** with `__slots__`: Maintains observations per metric. Methods: `store` (calculate and record metrics), `reset` (clear observations), `maximize` (feed summed observations to hypothesis targeting).

6. **Module-level `maximize` function**: Invokes hypothesis targeting for each metric given a case and response.

---

## Target 4: Transport & Serialization

The transport layer is being rebuilt around a proper abstraction. Each transport (HTTP/requests, WSGI, ASGI) will extend a `BaseTransport` that handles serializer registration and media type matching.

### Requirements

1. **`BaseTransport` generic class**: Maintains a serializer registry keyed by media type. Methods: `serializer` (decorator for registration), `unregister_serializer`, `get_first_matching_media_type`, `get_matching_media_types` (supports wildcard matching and known media type variations for json, xml, plain_text, yaml).

2. **`SerializationContext` dataclass** with `__slots__`: Carries the generated test `Case`.

3. **Top-level `schemathesis.serializer` function**: Registers a serializer function across all three transports (requests, WSGI, ASGI). The serializer receives a context and value, returns bytes or None to omit the request body.

4. **Transport selection via `transport.get`**: Selects the appropriate transport instance based on whether an app is provided and whether it is async.

---

## Target 5: Response Class

Different HTTP transports return different response types. We plan to introduce a unified `Response` class that normalizes them all into a consistent interface.

### Requirements

1. **`Response` class** in `schemathesis.core.transport` with `__slots__`: Exposes status code, normalized headers (lowercase keys, list values), content bytes, the prepared request, elapsed time, verify flag, message, HTTP version, and encoding. Constructor normalizes header keys to lowercase.

2. **Factory classmethods**: `from_requests`, `from_httpx`, `from_wsgi`, `from_any`. Each extracts data from its respective response type and normalizes it. `from_any` dispatches based on isinstance checks.

3. **Properties**: `text` (decoded content), `json` (parsed with caching), `body_size`, `encoded_body` (base64-encoded with caching).

---

## Target 6: Check System

The check registration system is being redesigned with a richer context object that provides access to configuration and operation state.

### Requirements

1. **`CheckFunction` protocol**: A callable taking context, response, and case (note: different argument order from v3).

2. **`CheckContext` class** with `__slots__`: Provides access to check configuration. Loads enabled checks from the registry based on config.

3. **`@schemathesis.check` decorator**: Registers a function into the `CHECKS` registry. Returns the function unchanged.

4. **`Registry` generic class** in `schemathesis.core.registries`: Container supporting `register`, `unregister`, `get_all_names`, `get_all`, `get_by_names`.

5. **Built-in `not_a_server_error` check**: Validates response status code against configured expected statuses, raises failure on mismatch. For GraphQL schemas, additionally validates response JSON structure.

---

## Public API Path Clarifications

- Configuration APIs are expected at `schemathesis.config`, with helper modules such as `schemathesis.config._env`, `_phases`, `_generation`, `_health_check`, `_error`, and `_checks`. `SchemathesisConfig`, `ConfigError`, `PhasesConfig`, `GenerationConfig`, `HealthCheck`, and `path_to_section_name` should be importable from those documented paths.
- The v4 public namespace includes `schemathesis.openapi`, `schemathesis.pytest`, `schemathesis.transport`, `schemathesis.core.transport`, and `schemathesis.core.registries`. Add compatibility modules or re-export layers rather than leaving only the old v3 paths.
- `GenerationMode` is a string enum with `POSITIVE` / `NEGATIVE` values and `is_positive` / `is_negative` convenience properties; it is exported both from `schemathesis.generation.modes` and the top-level package.
- `MetricContext`, `MetricCollector`, `metric`, `response_time`, and `maximize` live in `schemathesis.generation.metrics`; metrics are registered by name and feed summed observations to `hypothesis.target`.
- `BaseTransport`, `SerializationContext`, `serializer`, and `get` live in `schemathesis.transport`, with singleton transports exposed from `schemathesis.transport.requests`, `.wsgi`, and `.asgi`.
- `Response` lives in `schemathesis.core.transport`. Its constructor normalizes headers to lowercase list values, `body_size` is `None` for empty content, `.json()` caches parsed JSON, `.encoded_body` caches base64 content, `from_requests` / `from_httpx` / `from_any` normalize client responses, `USER_AGENT` contains `schemathesis/`, and `DEFAULT_RESPONSE_TIMEOUT` is `10`.
- `Registry` lives in `schemathesis.core.registries`; check APIs live in `schemathesis.checks` with `CheckContext`, `CheckFunction`, `CHECKS`, `check`, `not_a_server_error`, and `load_all_checks`.

## Phase Granularity Note

- Each roadmap phase covers many independent public API checks. Passing some checks inside a phase is useful progress, but the benchmark phase only turns green when all checks in that phase pass.

---

## Completion Criteria

- All new classes and functions importable from their documented paths
- Configuration discovery, parsing, and validation work correctly
- Factory methods on Response produce correct normalized output
- Metric, check, and serializer decorators register functions properly
- Registry provides correct lookup by name
- Existing backward-compatible paths removed (this is a breaking-change release)
