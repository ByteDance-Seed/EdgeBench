# ============================================================================
# Configuration File Parser in Arc
# ============================================================================
# Parses TOML/INI-style configuration files. Supports sections, key-value
# pairs, nested values, arrays, type coercion, defaults, validation, and
# config merging.
# Demonstrates: regex, pattern matching, pipelines, closures, maps, lists,
# string interpolation, mutation, recursion, higher-order functions
# ============================================================================

use regex
use json
use collections

# --- Patterns ---

let SECTION_RE = "^\\[([^\\]]+)\\]\\s*$"
let KV_RE = "^([\\w.]+)\\s*=\\s*(.+)\\s*$"
let COMMENT_RE = "^\\s*[#;]"
let EMPTY_RE = "^\\s*$"
let ARRAY_RE = "^\\[(.*)\\]$"
let QUOTED_RE = "^\"(.*)\"$"
let INT_RE = "^-?\\d+$"
let FLOAT_RE = "^-?\\d+\\.\\d+$"
let BOOL_TRUE_RE = "^(true|yes|on|1)$"
let BOOL_FALSE_RE = "^(false|no|off|0)$"

# --- Type Coercion ---

pub fn coerce_value(raw) {
    let trimmed = raw |> trim()

    # Quoted string
    let quoted = regex.capture(QUOTED_RE, trimmed)
    if quoted != nil { ret {kind: "string", value: quoted[1]} }

    # Boolean
    if regex.test(BOOL_TRUE_RE, trimmed) { ret {kind: "bool", value: true} }
    if regex.test(BOOL_FALSE_RE, trimmed) { ret {kind: "bool", value: false} }

    # Integer
    if regex.test(INT_RE, trimmed) { ret {kind: "int", value: parse_int(trimmed)} }

    # Float
    if regex.test(FLOAT_RE, trimmed) { ret {kind: "float", value: parse_float(trimmed)} }

    # Array
    let arr = regex.capture(ARRAY_RE, trimmed)
    if arr != nil {
        let items = arr[1] |> split(",") |> map(s => coerce_value(s).value)
        ret {kind: "array", value: items}
    }

    # Default: string
    {kind: "string", value: trimmed}
}

fn trim(s) => s # simplified — assume trimmed input
fn split(s, sep) {
    # Simple split implementation
    let mut parts = []
    let mut current = ""
    for ch in chars(s) {
        if ch == sep {
            parts = parts ++ [current]
            current = ""
        } el {
            current = current ++ ch
        }
    }
    parts ++ [current]
}

fn parse_int(s) {
    let mut result = 0
    let mut negative = false
    let mut i = 0
    for ch in chars(s) {
        match ch {
            "-" => { if i == 0 { negative = true } },
            "0" => { result = result * 10 },
            "1" => { result = result * 10 + 1 },
            "2" => { result = result * 10 + 2 },
            "3" => { result = result * 10 + 3 },
            "4" => { result = result * 10 + 4 },
            "5" => { result = result * 10 + 5 },
            "6" => { result = result * 10 + 6 },
            "7" => { result = result * 10 + 7 },
            "8" => { result = result * 10 + 8 },
            "9" => { result = result * 10 + 9 },
            _ => {}
        }
        i = i + 1
    }
    if negative { -result } el { result }
}

fn parse_float(s) => parse_int(s) # simplified

# --- Parser ---

pub fn parse(text) {
    let lines = text |> split_lines()
    let mut config = {}
    let mut current_section = "__root__"
    let mut errors = []
    let mut line_num = 0

    for line in lines {
        line_num = line_num + 1

        if regex.test(EMPTY_RE, line) or regex.test(COMMENT_RE, line) {
            # Skip empty lines and comments
        } el {
            let section = regex.capture(SECTION_RE, line)
            if section != nil {
                current_section = section[1]
                if config[current_section] == nil {
                    config[current_section] = {}
                }
            } el {
                let kv = regex.capture(KV_RE, line)
                if kv != nil {
                    let key = kv[1]
                    let raw_value = kv[2]
                    let coerced = coerce_value(raw_value)
                    if key |> contains(".") {
                        let parts = key |> split(".")
                        set_nested(config, current_section, parts, coerced.value)
                    } el {
                        if config[current_section] == nil {
                            config[current_section] = {}
                        }
                        config[current_section][key] = coerced.value
                    }
                } el {
                    errors = errors ++ [{line: line_num, text: line, error: "Unrecognized syntax"}]
                }
            }
        }
    }

    {config: config, errors: errors}
}

fn split_lines(text) => text |> split("\n")

fn contains(s, ch) {
    for c in chars(s) {
        if c == ch { ret true }
    }
    false
}

fn set_nested(config, section, parts, value) {
    if config[section] == nil { config[section] = {} }
    let mut current = config[section]
    for i in 0..(len(parts) - 1) {
        let key = parts[i]
        if current[key] == nil { current[key] = {} }
        current = current[key]
    }
    current[parts[len(parts) - 1]] = value
}

# --- Config Access ---

pub fn get(config, section, key) {
    match config[section] {
        nil => nil,
        s => s[key]
    }
}

pub fn get_or(config, section, key, default) {
    let val = get(config, section, key)
    if val == nil { default } el { val }
}

pub fn get_nested(config, path) {
    let parts = path |> split(".")
    let mut current = config
    for part in parts {
        match current {
            nil => { ret nil },
            _ => { current = current[part] }
        }
    }
    current
}

pub fn sections(config) => keys(config)

pub fn keys_in(config, section) => match config[section] {
    nil => [],
    s => keys(s)
}

# --- Validation ---

pub fn validate(config, schema) {
    let mut errors = []

    for rule in schema {
        let value = get(config, rule.section, rule.key)

        if rule.required and value == nil {
            errors = errors ++ [{
                path: "{rule.section}.{rule.key}",
                error: "Required field missing"
            }]
        } el {
            if value != nil {
                # Type check
                match rule.kind {
                    "string" => {
                        if type_of(value) != "string" {
                            errors = errors ++ [{path: "{rule.section}.{rule.key}", error: "Expected string"}]
                        }
                    },
                    "int" => {
                        if type_of(value) != "number" {
                            errors = errors ++ [{path: "{rule.section}.{rule.key}", error: "Expected integer"}]
                        }
                    },
                    "bool" => {
                        if type_of(value) != "boolean" {
                            errors = errors ++ [{path: "{rule.section}.{rule.key}", error: "Expected boolean"}]
                        }
                    },
                    _ => {}
                }

                # Range check
                if rule.min != nil and value < rule.min {
                    errors = errors ++ [{path: "{rule.section}.{rule.key}", error: "Below minimum {rule.min}"}]
                }
                if rule.max != nil and value > rule.max {
                    errors = errors ++ [{path: "{rule.section}.{rule.key}", error: "Above maximum {rule.max}"}]
                }

                # Allowed values
                if rule.allowed != nil {
                    let valid = len(rule.allowed |> filter(a => a == value)) > 0
                    if not valid {
                        errors = errors ++ [{path: "{rule.section}.{rule.key}", error: "Not in allowed values: {rule.allowed}"}]
                    }
                }
            }
        }
    }
    {valid: len(errors) == 0, errors: errors}
}

fn type_of(v) => match v {
    true => "boolean",
    false => "boolean",
    nil => "nil",
    _ => "string" # simplified
}

# --- Defaults ---

pub fn with_defaults(config, defaults) {
    let mut result = {}
    # Copy defaults
    for section in keys(defaults) {
        result[section] = {}
        for key in keys(defaults[section]) {
            result[section][key] = defaults[section][key]
        }
    }
    # Override with config values
    for section in keys(config) {
        if result[section] == nil { result[section] = {} }
        for key in keys(config[section]) {
            result[section][key] = config[section][key]
        }
    }
    result
}

# --- Merge Configs ---

pub fn merge(base, override_cfg) {
    let mut result = {}
    for section in keys(base) {
        result[section] = {}
        for key in keys(base[section]) {
            result[section][key] = base[section][key]
        }
    }
    for section in keys(override_cfg) {
        if result[section] == nil { result[section] = {} }
        for key in keys(override_cfg[section]) {
            result[section][key] = override_cfg[section][key]
        }
    }
    result
}

# --- Serialization ---

pub fn to_string(config) {
    let mut lines = []
    for section in keys(config) {
        if section != "__root__" {
            lines = lines ++ ["[{section}]"]
        }
        for key in keys(config[section]) {
            let val = config[section][key]
            let str_val = format_value(val)
            lines = lines ++ ["{key} = {str_val}"]
        }
        lines = lines ++ [""]
    }
    lines |> join_lines("\n")
}

fn format_value(v) => match v {
    true => "true",
    false => "false",
    nil => "nil",
    _ => "\"{v}\""
}

fn join_lines(lst, sep) {
    if len(lst) == 0 { ret "" }
    if len(lst) == 1 { ret "{lst[0]}" }
    let first = lst[0]
    let rest = drop(lst, 1)
    "{first}{sep}{join_lines(rest, sep)}"
}

# --- Test ---

pub fn run() {
    print("=== Config Parser Demo ===\n")

    let config_text = "[server]
host = \"localhost\"
port = 8080
debug = true
workers = 4

[database]
host = \"db.example.com\"
port = 5432
name = \"myapp\"
pool_size = 20
ssl = true

[logging]
level = \"info\"
file = \"/var/log/app.log\"
max_size = 10485760
rotate = true

[auth]
secret = \"super-secret-key-123\"
token_ttl = 3600
providers = [google, github, email]

# Redis cache config
[cache]
enabled = true
ttl = 300
max_entries = 10000"

    let result = parse(config_text)
    let config = result.config

    print("Parsed sections: {sections(config)}")
    print("Parse errors: {len(result.errors)}")

    # Access values
    print("\nServer host: {get(config, "server", "host")}")
    print("Server port: {get(config, "server", "port")}")
    print("DB pool size: {get(config, "database", "pool_size")}")
    print("Log level: {get(config, "logging", "level")}")
    print("Auth providers: {get(config, "auth", "providers")}")

    # Defaults
    print("\n--- With Defaults ---")
    let defaults = {
        server: {host: "0.0.0.0", port: 3000, workers: 1},
        cache: {enabled: false, ttl: 60}
    }
    let with_def = with_defaults(config, defaults)
    print("Cache TTL (from config): {get(with_def, "cache", "ttl")}")

    # Validation
    print("\n--- Validation ---")
    let schema = [
        {section: "server", key: "host", required: true, kind: "string"},
        {section: "server", key: "port", required: true, kind: "int", min: 1, max: 65535},
        {section: "database", key: "host", required: true, kind: "string"},
        {section: "database", key: "name", required: true, kind: "string"},
        {section: "logging", key: "level", required: true, kind: "string",
         allowed: ["trace", "debug", "info", "warn", "error"]}
    ]
    let validation = validate(config, schema)
    print("Valid: {validation.valid}")
    if not validation.valid {
        for e in validation.errors {
            print("  ❌ {e.path}: {e.error}")
        }
    }

    # Merge (e.g., dev overrides)
    print("\n--- Config Merge ---")
    let dev_overrides = {
        server: {debug: true, port: 3000},
        database: {host: "localhost", name: "myapp_dev"}
    }
    let merged = merge(config, dev_overrides)
    print("Merged DB host: {get(merged, "database", "host")}")
    print("Merged server port: {get(merged, "server", "port")}")

    # Serialize back
    print("\n--- Serialized Config ---")
    print(to_string(config))

    print("\n✓ Config parser demo complete!")
}

run()
