# Cron Expression Parser
# Demonstrates: string parsing, pattern matching, pipelines

fn parse_field(field, min_val, max_val) {
  if field == "*" { ret 0..(max_val+1) }
  if contains(field, "/") {
    let parts = split(field, "/")
    let step = int(parts[1])
    let mut result = []
    let mut i = min_val
    for _ in min_val..(max_val+1) {
      if i > max_val { ret result }
      result = push(result, i)
      i = i + step
    }
    ret result
  }
  if contains(field, ",") {
    ret split(field, ",") |> map(int)
  }
  if contains(field, "-") {
    let parts = split(field, "-")
    ret int(parts[0])..(int(parts[1])+1)
  }
  [int(field)]
}

fn parse_cron(expr) {
  let fields = split(expr, " ")
  if len(fields) != 5 {
    ret Err("Invalid cron: expected 5 fields, got {len(fields)}")
  }
  Ok({
    minutes: parse_field(fields[0], 0, 59),
    hours: parse_field(fields[1], 0, 23),
    days: parse_field(fields[2], 1, 31),
    months: parse_field(fields[3], 1, 12),
    weekdays: parse_field(fields[4], 0, 6)
  })
}

fn describe_cron(expr) {
  let result = parse_cron(expr)
  if is_err(result) { ret unwrap_err(result) }
  let parsed = unwrap(result)
  let min_desc = if len(parsed.minutes) == 60 { "every minute" }
    el if len(parsed.minutes) == 1 { "at minute {head(parsed.minutes)}" }
    el { "at minutes {parsed.minutes}" }
  let hour_desc = if len(parsed.hours) == 24 { "every hour" }
    el if len(parsed.hours) == 1 { "at hour {head(parsed.hours)}" }
    el { "at hours {parsed.hours}" }
  "{min_desc}, {hour_desc}"
}

# Demo
print("=== Cron Parser ===")

let expressions = [
  "*/5 * * * *",
  "0 9 * * 1-5",
  "30 2 1 * *",
  "0 0 * * 0",
  "*/15 9-17 * * *"
]

for expr in expressions {
  print("'{expr}' => {describe_cron(expr)}")
}

# Error handling
let bad = parse_cron("invalid")
print("Invalid cron: is_err={is_err(bad)}")
