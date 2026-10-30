# Rate Limiter
# Demonstrates: maps, time functions, mutation, closures

fn new_limiter(max_requests, window_ms) => {
  max: max_requests,
  window: window_ms,
  requests: {}
}

fn check_rate(limiter, client_id) {
  let now = time_ms()
  let window_start = now - limiter.window

  # Get existing timestamps for this client
  let existing = if limiter.requests[client_id] != nil {
    limiter.requests[client_id]
  } el {
    []
  }

  # Filter to only recent requests within window
  let recent = existing |> filter(t => t > window_start)

  if len(recent) >= limiter.max {
    let oldest = head(recent)
    let retry_after = oldest + limiter.window - now
    {allowed: false, remaining: 0, retry_after: retry_after}
  } el {
    # Record this request
    let updated = push(recent, now)
    limiter.requests[client_id] = updated
    {allowed: true, remaining: limiter.max - len(updated), retry_after: 0}
  }
}

# Demo
print("=== Rate Limiter ===")
let mut limiter = new_limiter(3, 1000)

for i in 1..7 {
  let result = check_rate(limiter, "user_1")
  let status = if result.allowed { "✓ ALLOWED" } el { "✗ DENIED" }
  print("Request {i}: {status} (remaining: {result.remaining})")
}

print("")
print("Different client:")
let result = check_rate(limiter, "user_2")
print("user_2 request: allowed={result.allowed}, remaining={result.remaining}")
