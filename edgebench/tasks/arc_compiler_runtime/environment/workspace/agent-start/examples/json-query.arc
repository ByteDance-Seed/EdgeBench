# JSON Query Engine
# Demonstrates: recursion, pattern matching, maps, pipelines

# Simple path-based query on nested maps
fn query(data, path) {
  let parts = split(path, ".")
  let mut current = data
  for part in parts {
    if current == nil { ret nil }
    current = current[part]
  }
  current
}

# Select multiple fields
fn select_fields(record, fields) {
  let mut result = {}
  for f in fields {
    result[f] = record[f]
  }
  result
}

# Where filter on a list of records
fn where_eq(records, field, value) {
  records |> filter(r => r[field] == value)
}

fn where_gt(records, field, value) {
  records |> filter(r => r[field] > value)
}

# Sample database
let db = {
  users: [
    {id: 1, name: "Alice", age: 30, dept: "eng"},
    {id: 2, name: "Bob", age: 25, dept: "sales"},
    {id: 3, name: "Charlie", age: 35, dept: "eng"},
    {id: 4, name: "Diana", age: 28, dept: "eng"},
    {id: 5, name: "Eve", age: 32, dept: "sales"}
  ],
  config: {
    app: {name: "MyApp", version: "1.0"},
    db: {host: "localhost", port: 5432}
  }
}

# Run queries
print("=== JSON Query Engine ===")

# Path queries
print("App name: {query(db, "config.app.name")}")
print("DB host: {query(db, "config.db.host")}")

# Filter queries
let engineers = where_eq(db.users, "dept", "eng")
print("Engineers: {engineers |> map(u => u.name)}")

let senior = where_gt(db.users, "age", 30)
print("Over 30: {senior |> map(u => u.name)}")

# Select specific fields
let names_ages = db.users |> map(u => select_fields(u, ["name", "age"]))
print("Names and ages: {names_ages}")

# Aggregation
let eng_ages = engineers |> map(u => u.age)
print("Eng avg age: {sum(eng_ages) / len(eng_ages)}")
print("Total users: {len(db.users)}")
