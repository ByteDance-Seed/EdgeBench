# Arc Standard Library: error module
# Structured error handling

# Create a structured error
pub fn error(code, message) => error_new(code, message)

# Check if a value is an error
pub fn is_error(value) => error_is_error(value)

# Wrap an error with additional context
pub fn wrap_error(err, context) => error_wrap(err, context)

# Try executing a function, return Ok/Err result
pub fn try_fn(f) => error_try(f)

# Execute fn, call handler if result is an error
pub fn try_catch(f, handler) {
  let result = f()
  if is_error(result) { handler(result) }
  el { result }
}

# Execute fn, always run cleanup
pub fn try_finally(f, cleanup) {
  let result = f()
  cleanup()
  result
}

# Full try/catch/finally
pub fn try_catch_finally(f, handler, cleanup) {
  let result = f()
  let handled = if is_error(result) { handler(result) } el { result }
  cleanup()
  handled
}

# Throw an error (raises a runtime exception)
pub fn throw(code, message) => error_throw(code, message)

# Retry a function up to n times, returning the first success or last error
pub fn retry(f, times) => error_retry(f, times)
