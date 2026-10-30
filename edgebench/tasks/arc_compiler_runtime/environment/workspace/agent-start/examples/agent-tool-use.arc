# Agent tool use

let weather = @GET "api/weather/nyc"
print("Weather: {weather}")

# Custom tool call
let summary = @summarize("The quick brown fox jumps over the lazy dog")
print("Summary: {summary}")

# Chained tool usage
let users = @GET "api/users"
print("All users: {users}")
