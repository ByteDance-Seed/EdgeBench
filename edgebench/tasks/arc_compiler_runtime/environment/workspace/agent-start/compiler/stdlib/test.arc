# Arc Standard Library: test module
# A lightweight testing framework

let mut _passed = 0
let mut _failed = 0
let mut _current_group = ""

pub fn describe(name, f) {
  _current_group = name
  print("--- " ++ name ++ " ---")
  f()
  print("")
}

pub fn it(name, f) {
  let label = if _current_group != "" { _current_group ++ " > " ++ name } el { name }
  f()
  _passed = _passed + 1
  print("  ✓ " ++ name)
}

pub fn expect_eq(a, b, msg) {
  let m = msg or ("Expected " ++ str(a) ++ " to equal " ++ str(b))
  assert(a == b, m)
}

pub fn expect_neq(a, b, msg) {
  let m = msg or ("Expected " ++ str(a) ++ " to not equal " ++ str(b))
  assert(a != b, m)
}

pub fn expect_true(val, msg) {
  let m = msg or ("Expected truthy, got " ++ str(val))
  assert(val, m)
}

pub fn expect_false(val, msg) {
  let m = msg or ("Expected falsy, got " ++ str(val))
  assert(not val, m)
}

pub fn expect_nil(val, msg) {
  let m = msg or ("Expected nil, got " ++ str(val))
  assert(val == nil, m)
}

pub fn expect_gt(a, b, msg) {
  let m = msg or ("Expected " ++ str(a) ++ " > " ++ str(b))
  assert(a > b, m)
}

pub fn expect_lt(a, b, msg) {
  let m = msg or ("Expected " ++ str(a) ++ " < " ++ str(b))
  assert(a < b, m)
}

pub fn run_tests() {
  print("========================")
  print("Tests: " ++ str(_passed) ++ " passed, " ++ str(_failed) ++ " failed")
  print("========================")
}
