# JSON Data Transformer
# Demonstrates: nested maps, pipelines, comprehensions
# Showcases Arc's expressiveness for data transformation tasks

# Sample API response (nested data)
let api_response = {
  users: [
    {name: "Alice", age: 30, roles: ["admin", "user"], active: true},
    {name: "Bob", age: 25, roles: ["user"], active: false},
    {name: "Charlie", age: 35, roles: ["admin", "moderator"], active: true},
    {name: "Diana", age: 28, roles: ["user"], active: true}
  ],
  meta: {total: 4, page: 1}
}

# Extract active admins with pipeline
let active_admins = api_response.users
  |> filter(u => u.active)
  |> filter(u => contains(u.roles, "admin"))
  |> map(u => {name: u.name, age: u.age})

print("Active admins: {active_admins}")

# Compute stats with pipeline
let ages = api_response.users |> map(u => u.age)
let stats = {
  active: api_response.users |> filter(u => u.active) |> len,
  avg_age: sum(ages) / len(ages),
  total: len(api_response.users)
}

print("Stats: {stats}")

# Reshape for a different API format
let output = [
  {
    display_name: u.name,
    age: u.age,
    status: if u.active { "active" } el { "inactive" }
  }
  for u in api_response.users
]

print("Transformed:")
for item in output {
  print("  {item.display_name} ({item.age}) - {item.status}")
}
