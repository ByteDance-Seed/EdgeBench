# URL Shortener
# Demonstrates: maps, string operations, mutation, hashing

let mut url_store = {}
let mut counter = 1000

fn base62_encode(num) {
  let charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let char_list = chars(charset)
  if num == 0 { ret "a" }
  let mut result = ""
  let mut n = num
  for _ in 0..10 {
    if n <= 0 { ret result }
    let remainder = n % 62
    result = char_at(charset, remainder) ++ result
    n = n / 62
  }
  result
}

fn shorten(url) {
  counter = counter + 1
  let code = base62_encode(counter)
  let short = "s.ho/" ++ code
  url_store[code] = {url: url, clicks: 0, created: time_ms()}
  short
}

fn resolve(short_code) {
  let entry = url_store[short_code]
  if entry == nil { ret Err("Not found: {short_code}") }
  url_store[short_code] = {
    url: entry.url,
    clicks: entry.clicks + 1,
    created: entry.created
  }
  Ok(entry.url)
}

fn stats(short_code) {
  let entry = url_store[short_code]
  if entry == nil { ret nil }
  {code: short_code, url: entry.url, clicks: entry.clicks}
}

# Demo
print("=== URL Shortener ===")

let urls = [
  "https://example.com/very/long/path/to/page",
  "https://example.invalid/redacted",
  "https://docs.arc-lang.dev/getting-started"
]

let mut shorts = []
for url in urls {
  let short = shorten(url)
  shorts = push(shorts, short)
  print("Shortened: {url}")
  print("  -> {short}")
}

print("")
print("Resolving first URL:")
let code = "rr"  # Will depend on counter
let all_keys = keys(url_store)
let first_key = head(all_keys)
let resolved = resolve(first_key)
if is_ok(resolved) {
  print("  {first_key} -> {unwrap(resolved)}")
}

# Check stats
let s = stats(first_key)
if s != nil {
  print("  Clicks: {s.clicks}")
}
