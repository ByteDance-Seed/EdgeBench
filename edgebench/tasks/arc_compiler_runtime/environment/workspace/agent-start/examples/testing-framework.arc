# Mini Testing Framework
# Demonstrates: closures, error handling, mutation, Result types

let mut tests = []
let mut passed = 0
let mut failed = 0

fn test(name, body) {
  tests = push(tests, {name: name, body: body})
}

fn expect_eq(actual, expected, msg = "") {
  if actual != expected {
    let label = if msg != "" { msg } el { "values" }
    print("    FAIL: expected {expected}, got {actual} ({label})")
    ret false
  }
  true
}

fn run_tests() {
  print("Running {len(tests)} tests...\n")
  for t in tests {
    let result = Ok(t.body())
    if is_ok(result) {
      print("  ✓ {t.name}")
      passed = passed + 1
    } el {
      print("  ✗ {t.name}: {unwrap_err(result)}")
      failed = failed + 1
    }
  }
  print("\n{passed} passed, {failed} failed, {len(tests)} total")
}

# Define tests
test("addition", () => {
  expect_eq(2 + 2, 4, "basic add")
  expect_eq(-1 + 1, 0, "negative")
})

test("string ops", () => {
  expect_eq(len("hello"), 5, "string length")
  expect_eq(upper("hi"), "HI", "uppercase")
  expect_eq("a" ++ "b", "ab", "concat")
})

test("list ops", () => {
  let nums = [1, 2, 3, 4, 5]
  expect_eq(len(nums), 5, "list length")
  expect_eq(sum(nums), 15, "sum")
  expect_eq(head(nums), 1, "head")
  expect_eq(last(nums), 5, "last")
})

test("map ops", () => {
  let m = {a: 1, b: 2, c: 3}
  expect_eq(m.a, 1, "access")
  expect_eq(len(keys(m)), 3, "keys count")
})

test("pattern matching", () => {
  fn classify(n) => match n {
    0 => "zero",
    1 => "one",
    _ => "other"
  }
  expect_eq(classify(0), "zero")
  expect_eq(classify(1), "one")
  expect_eq(classify(42), "other")
})

test("pipelines", () => {
  let result = [1, 2, 3, 4, 5]
    |> filter(x => x > 2)
    |> map(x => x * 10)
    |> sum
  expect_eq(result, 120)
})

test("Result types", () => {
  let ok = Ok(42)
  let err = Err("nope")
  expect_eq(is_ok(ok), true)
  expect_eq(is_err(err), true)
  expect_eq(unwrap(ok), 42)
  expect_eq(unwrap_or(err, 0), 0)
})

# Run all
print("=== Test Framework ===")
run_tests()
