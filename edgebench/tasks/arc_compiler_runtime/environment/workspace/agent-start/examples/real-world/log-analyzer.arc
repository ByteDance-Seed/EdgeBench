# ============================================================================
# Log File Analyzer in Arc
# ============================================================================
# Parses log files, extracts timestamps/levels/messages, filters by level
# and date range, aggregates error counts, and generates summary reports.
# Demonstrates: regex, pipelines, pattern matching, closures, maps, lists,
# string interpolation, mutation, higher-order functions, destructuring
# ============================================================================

use regex
use datetime
use collections
use io

# --- Log Entry Parsing ---

let LOG_PATTERN = "^\\[(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2})\\]\\s+\\[(\\w+)\\]\\s+\\[([^\\]]+)\\]\\s+(.*)"

pub fn parse_log_line(line) {
    let m = regex.capture(LOG_PATTERN, line)
    match m {
        nil => nil,
        _ => {
            timestamp: m[1],
            level: m[2] |> to_upper(),
            source: m[3],
            message: m[4],
            raw: line
        }
    }
}

pub fn parse_log_lines(lines) {
    lines
        |> map(parse_log_line)
        |> filter(entry => entry != nil)
}

fn to_upper(s) => match s {
    "debug" => "DEBUG", "info" => "INFO", "warn" => "WARN",
    "warning" => "WARNING", "error" => "ERROR", "fatal" => "FATAL",
    "trace" => "TRACE", _ => s
}

# --- Log Level Severity ---

fn level_severity(level) => match level {
    "TRACE" => 0,
    "DEBUG" => 1,
    "INFO"  => 2,
    "WARN"  => 3,
    "WARNING" => 3,
    "ERROR" => 4,
    "FATAL" => 5,
    _ => -1
}

fn level_color(level) => match level {
    "DEBUG" => "🔵",
    "INFO"  => "🟢",
    "WARN"  => "🟡",
    "WARNING" => "🟡",
    "ERROR" => "🔴",
    "FATAL" => "💀",
    _ => "⚪"
}

# --- Filtering ---

pub fn filter_by_level(entries, min_level) {
    let min_sev = level_severity(min_level)
    entries |> filter(e => level_severity(e.level) >= min_sev)
}

pub fn filter_by_source(entries, source) {
    entries |> filter(e => e.source == source)
}

pub fn filter_by_date_range(entries, start, end) {
    entries |> filter(e => e.timestamp >= start and e.timestamp <= end)
}

pub fn filter_by_message(entries, pattern) {
    let re = regex.compile(pattern)
    entries |> filter(e => regex.test(re, e.message))
}

# --- Aggregation ---

pub fn count_by_level(entries) {
    let mut counts = {}
    for e in entries {
        let key = e.level
        counts[key] = (counts[key] or 0) + 1
    }
    counts
}

pub fn count_by_source(entries) {
    let mut counts = {}
    for e in entries {
        let key = e.source
        counts[key] = (counts[key] or 0) + 1
    }
    counts
}

pub fn count_by_hour(entries) {
    let mut counts = {}
    for e in entries {
        let hour = e.timestamp |> take(13) # "2024-01-15T14"
        counts[hour] = (counts[hour] or 0) + 1
    }
    counts
}

pub fn error_frequency(entries, window_minutes) {
    let errors = entries |> filter_by_level("ERROR")
    let mut windows = {}
    for e in errors {
        # Bucket by window
        let ts = e.timestamp |> take(16) # "2024-01-15T14:30"
        windows[ts] = (windows[ts] or 0) + 1
    }
    windows
}

pub fn group_by(entries, key_fn) {
    let mut groups = {}
    for e in entries {
        let key = key_fn(e)
        if groups[key] == nil { groups[key] = [] }
        groups[key] = groups[key] ++ [e]
    }
    groups
}

# --- Pattern Detection ---

pub fn find_error_bursts(entries, threshold, window_size) {
    let errors = entries |> filter_by_level("ERROR")
    let mut bursts = []

    for i in 0..len(errors) {
        let mut count = 0
        let start_ts = errors[i].timestamp
        for j in i..len(errors) {
            # Simple windowing by position
            if j - i < window_size {
                count = count + 1
            }
        }
        if count >= threshold {
            bursts = bursts ++ [{
                start: start_ts,
                count: count,
                index: i
            }]
        }
    }
    bursts |> deduplicate()
}

fn deduplicate(lst) {
    let mut seen = {}
    let mut result = []
    for item in lst {
        let key = "{item.start}"
        if seen[key] != true {
            seen[key] = true
            result = result ++ [item]
        }
    }
    result
}

pub fn find_repeated_errors(entries) {
    let errors = entries |> filter_by_level("ERROR")
    let by_msg = group_by(errors, e => e.message)
    let mut repeated = []
    for msg in keys(by_msg) {
        if len(by_msg[msg]) > 1 {
            repeated = repeated ++ [{
                message: msg,
                count: len(by_msg[msg]),
                first: by_msg[msg][0].timestamp,
                last: by_msg[msg][len(by_msg[msg]) - 1].timestamp
            }]
        }
    }
    repeated |> sort_by_count()
}

fn sort_by_count(lst) {
    # Simple sort descending by count
    let mut result = map(lst, x => x)
    for i in 0..len(result) {
        for j in (i + 1)..len(result) {
            if result[j].count > result[i].count {
                let temp = result[i]
                result[i] = result[j]
                result[j] = temp
            }
        }
    }
    result
}

# --- Report Generation ---

pub fn generate_report(entries) {
    let total = len(entries)
    let by_level = count_by_level(entries)
    let by_source = count_by_source(entries)
    let errors = entries |> filter_by_level("ERROR")
    let repeated = find_repeated_errors(entries)

    print("╔══════════════════════════════════════════╗")
    print("║         LOG ANALYSIS REPORT              ║")
    print("╠══════════════════════════════════════════╣")
    print("║ Total entries: {total}")
    print("║")
    print("║ By Level:")
    for level in ["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"] {
        let count = by_level[level] or 0
        if count > 0 {
            let pct = count * 100 / total
            let bar = "█".repeat(pct / 2)
            print("║   {level_color(level)} {level}: {count} ({pct}%) {bar}")
        }
    }

    print("║")
    print("║ By Source:")
    for source in keys(by_source) {
        print("║   [{source}]: {by_source[source]} entries")
    }

    if len(repeated) > 0 {
        print("║")
        print("║ Repeated Errors (top 5):")
        for i in 0..min(5, len(repeated)) {
            let r = repeated[i]
            print("║   {r.count}x: {r.message}")
            print("║      First: {r.first} | Last: {r.last}")
        }
    }

    if len(errors) > 0 {
        print("║")
        print("║ Recent Errors (last 5):")
        let recent = errors |> take_last(5)
        for e in recent {
            print("║   [{e.timestamp}] [{e.source}] {e.message}")
        }
    }

    print("╚══════════════════════════════════════════╝")
}

fn take_last(lst, n) {
    let start = max(0, len(lst) - n)
    lst |> drop(start)
}

fn min(a, b) => if a < b { a } el { b }
fn max(a, b) => if a > b { a } el { b }

# --- Sample Data Generator ---

fn generate_sample_logs(count) {
    let levels = ["DEBUG", "DEBUG", "INFO", "INFO", "INFO", "WARN", "ERROR", "FATAL"]
    let sources = ["api-server", "database", "auth-service", "worker", "cache"]
    let messages = {
        "DEBUG": ["Cache hit for key user:123", "Query took 45ms", "Connection pool: 8/20 active"],
        "INFO": ["Request processed in 120ms", "User login successful", "Batch job completed", "Health check OK"],
        "WARN": ["Response time exceeded threshold", "Connection pool running low", "Retry attempt 2/3"],
        "ERROR": ["Database connection timeout", "Authentication failed: invalid token", "Out of memory: heap allocation", "Request failed: 503 Service Unavailable"],
        "FATAL": ["Process crashed: segfault", "Cannot bind to port 8080"]
    }

    let mut seed = 42
    let mut logs = []

    for i in 0..count {
        seed = (seed * 1103515245 + 12345) % 2147483648
        let level = levels[seed % len(levels)]
        seed = (seed * 1103515245 + 12345) % 2147483648
        let source = sources[seed % len(sources)]
        let msgs = messages[level]
        seed = (seed * 1103515245 + 12345) % 2147483648
        let msg = msgs[seed % len(msgs)]
        let hour = (i * 3) % 24
        let minute = (i * 7) % 60
        let second = (i * 13) % 60

        let ts = "2024-01-15T{pad(hour)}:{pad(minute)}:{pad(second)}"
        logs = logs ++ ["[{ts}] [{level}] [{source}] {msg}"]
    }
    logs
}

fn pad(n) => if n < 10 { "0{n}" } el { "{n}" }

# --- Run ---

pub fn run() {
    print("=== Log Analyzer Demo ===\n")

    # Generate sample log data
    let raw_logs = generate_sample_logs(50)
    print("Generated {len(raw_logs)} sample log lines\n")

    # Parse
    let entries = parse_log_lines(raw_logs)
    print("Parsed {len(entries)} valid entries\n")

    # Full report
    generate_report(entries)

    # Filtered views
    print("\n--- Errors Only ---")
    let errors = entries |> filter_by_level("ERROR")
    for e in errors {
        print("{level_color(e.level)} [{e.timestamp}] [{e.source}] {e.message}")
    }

    print("\n--- By Source: database ---")
    let db_entries = entries |> filter_by_source("database")
    for e in db_entries {
        print("{level_color(e.level)} [{e.level}] {e.message}")
    }

    # Hourly distribution
    print("\n--- Hourly Distribution ---")
    let by_hour = count_by_hour(entries)
    for hour in keys(by_hour) {
        let bar = "█".repeat(by_hour[hour])
        print("  {hour}: {bar} ({by_hour[hour]})")
    }

    print("\n✓ Log analysis complete!")
}

run()
