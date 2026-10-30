# In-Memory Database
# Demonstrates: maps, mutation, closures, pipelines, Result types

let mut tables = {}
let mut auto_ids = {}

fn create_table(name) {
  tables[name] = []
  auto_ids[name] = 0
  Ok("Table '{name}' created")
}

fn insert_record(table, record) {
  if tables[table] == nil { ret Err("Table '{table}' not found") }
  auto_ids[table] = auto_ids[table] + 1
  let id = auto_ids[table]
  let mut row = {id: id}
  let ks = keys(record)
  for k in ks {
    row[k] = record[k]
  }
  tables[table] = push(tables[table], row)
  Ok(row)
}

fn select_all(table) {
  if tables[table] == nil { ret Err("Table '{table}' not found") }
  Ok(tables[table])
}

fn select_where(table, field, value) {
  if tables[table] == nil { ret Err("Table '{table}' not found") }
  let rows = tables[table] |> filter(r => r[field] == value)
  Ok(rows)
}

fn update_where(table, field, value, updates) {
  if tables[table] == nil { ret Err("Table '{table}' not found") }
  let mut count = 0
  tables[table] = tables[table] |> map(r => {
    if r[field] == value {
      count = count + 1
      let mut updated = r
      let uks = keys(updates)
      for k in uks {
        updated[k] = updates[k]
      }
      updated
    } el {
      r
    }
  })
  Ok(count)
}

fn delete_where(table, field, value) {
  if tables[table] == nil { ret Err("Table '{table}' not found") }
  let before = len(tables[table])
  tables[table] = tables[table] |> filter(r => r[field] != value)
  Ok(before - len(tables[table]))
}

fn count_rows(table) {
  if tables[table] == nil { ret 0 }
  len(tables[table])
}

# Demo
print("=== In-Memory Database ===")

create_table("users")
create_table("posts")

# Insert users
insert_record("users", {name: "Alice", age: 30, role: "admin"})
insert_record("users", {name: "Bob", age: 25, role: "user"})
insert_record("users", {name: "Charlie", age: 35, role: "admin"})
insert_record("users", {name: "Diana", age: 28, role: "user"})

print("Users: {count_rows("users")} rows")

# Query
let admins = select_where("users", "role", "admin")
if is_ok(admins) {
  let rows = unwrap(admins)
  print("Admins: {rows |> map(u => u.name)}")
}

# Update
let updated = update_where("users", "name", "Bob", {age: 26})
print("Updated {unwrap(updated)} rows")

# Delete
let deleted = delete_where("users", "name", "Charlie")
print("Deleted {unwrap(deleted)} rows")

print("Final user count: {count_rows("users")}")
let all = unwrap(select_all("users"))
for u in all {
  print("  [{u.id}] {u.name}, age {u.age}, role: {u.role}")
}
