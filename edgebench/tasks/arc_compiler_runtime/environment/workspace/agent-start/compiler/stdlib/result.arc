# Arc Standard Library: result module
# Result type pattern for error handling using native builtins

# Capture builtins before any shadowing
let _builtin_is_ok = is_ok
let _builtin_is_err = is_err
let _builtin_unwrap = unwrap
let _builtin_unwrap_or = unwrap_or
let _builtin_unwrap_err = unwrap_err
let _builtin_map_result = map_result

# Ok(value) - wraps a success value in a Result
pub fn ok(value) => Ok(value)

# err(error) - wraps an error in a Result
pub fn err(error) => Err(error)

# --- Clean aliases (no prefix stutter: result.is_ok instead of result.result_is_ok) ---

pub fn is_ok(result) => _builtin_is_ok(result)
pub fn is_err(result) => _builtin_is_err(result)
pub fn unwrap(result) => _builtin_unwrap(result)
pub fn unwrap_or(result, default) => _builtin_unwrap_or(result, default)
pub fn unwrap_err(result) => _builtin_unwrap_err(result)
pub fn map(result, f) => _builtin_map_result(result, f)
pub fn flat_map(result, f) {
  if _builtin_is_ok(result) {
    f(_builtin_unwrap(result))
  } el {
    result
  }
}

# try_fn - wraps a function call in a Result (uses native error_try)
pub fn try_fn(f) => error_try(f)

# --- Legacy prefixed names (backward compat) ---

pub fn result_is_ok(result) => _builtin_is_ok(result)
pub fn result_is_err(result) => _builtin_is_err(result)
pub fn result_unwrap(result) => _builtin_unwrap(result)
pub fn result_unwrap_or(result, default) => _builtin_unwrap_or(result, default)
pub fn result_map(result, f) => _builtin_map_result(result, f)
pub fn flat_map_result(result, f) {
  if _builtin_is_ok(result) {
    f(_builtin_unwrap(result))
  } el {
    result
  }
}
