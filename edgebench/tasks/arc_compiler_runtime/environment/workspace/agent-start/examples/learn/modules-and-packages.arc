# Learn Arc: Modules & Packages
# Demonstrates: use/pub, stdlib modules, module patterns

# --- Importing stdlib ---
use io
use crypto

# --- Exporting ---
pub fn greet(name) => "Hello, {name}!"
pub let VERSION = "1.0.0"
fn internal_helper(x) => x * 2    # private

# --- Using built-in functions ---

# String operations
print("=== Module Demo ===")
print(upper("hello"))          # HELLO
print(lower("WORLD"))          # world
print(trim("  hi  "))          # hi
print(replace("hello world", "world", "arc"))  # hello arc

# List operations
let nums = [3, 1, 4, 1, 5, 9]
print(sort(nums))              # [1, 1, 3, 4, 5, 9]
print(reverse(nums))           # [9, 5, 1, 4, 1, 3]
print(len(nums))               # 6

# Crypto module
let hash = sha256("hello")
print("SHA256: {hash}")

# --- Module Design Patterns ---

# Utility functions
pub fn slugify(text) {
  text |> lower |> split(" ") |> join("-")
}

pub fn truncate(text, max_len) {
  if len(text) <= max_len { text }
  el { slice(text, 0, max_len) ++ "..." }
}

# Formatting helpers
pub fn currency(amount) => "${amount}"
pub fn percent(value) => "{value}%"
pub fn pluralize(count, word) {
  if count == 1 { "{count} {word}" }
  el { "{count} {word}s" }
}

# Validators
pub fn is_email(s) => contains(s, "@") and contains(s, ".")
pub fn is_positive(n) => n > 0
pub fn is_non_empty(s) => len(trim(s)) > 0

# Demo
print("Slug: {slugify("Hello World Example")}")
print("Truncate: {truncate("This is a very long string", 15)}")
print("Currency: {currency(42.99)}")
print("Plural: {pluralize(1, "cat")} / {pluralize(3, "cat")}")
print("Email valid: {is_email("user@example.com")}")
