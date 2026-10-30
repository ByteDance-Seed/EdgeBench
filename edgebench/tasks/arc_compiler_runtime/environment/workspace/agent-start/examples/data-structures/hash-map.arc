# Hash Map Implementation
# Demonstrates: lists of lists (buckets), mutation, hashing

fn simple_hash(key, size) {
  let mut h = 0
  let chs = chars(str(key))
  for ch in chs {
    h = (h * 31 + ord(ch)) % size
  }
  h
}

fn new_hashmap(size = 16) => {
  buckets: [[] for _ in 0..size],
  size: size,
  count: 0
}

fn hm_set(hm, key, value) {
  let idx = simple_hash(key, hm.size)
  let bucket = hm.buckets[idx]
  # Check if key exists
  let mut found = false
  let mut new_bucket = []
  for entry in bucket {
    if entry.key == key {
      new_bucket = push(new_bucket, {key: key, value: value})
      found = true
    } el {
      new_bucket = push(new_bucket, entry)
    }
  }
  if not found {
    new_bucket = push(new_bucket, {key: key, value: value})
    hm.count = hm.count + 1
  }
  hm.buckets[idx] = new_bucket
}

fn hm_get(hm, key) {
  let idx = simple_hash(key, hm.size)
  let bucket = hm.buckets[idx]
  for entry in bucket {
    if entry.key == key { ret entry.value }
  }
  nil
}

fn hm_has(hm, key) => hm_get(hm, key) != nil

fn hm_delete(hm, key) {
  let idx = simple_hash(key, hm.size)
  let bucket = hm.buckets[idx]
  hm.buckets[idx] = bucket |> filter(e => e.key != key)
  hm.count = hm.count - 1
}

fn hm_keys(hm) {
  let mut result = []
  for bucket in hm.buckets {
    for entry in bucket {
      result = push(result, entry.key)
    }
  }
  result
}

# Demo
print("=== Hash Map ===")
let mut hm = new_hashmap(8)

hm_set(hm, "name", "Alice")
hm_set(hm, "age", 30)
hm_set(hm, "city", "NYC")
hm_set(hm, "role", "engineer")

print("name: {hm_get(hm, "name")}")
print("age: {hm_get(hm, "age")}")
print("has 'city': {hm_has(hm, "city")}")
print("has 'zip': {hm_has(hm, "zip")}")
print("count: {hm.count}")
print("keys: {hm_keys(hm)}")

# Update
hm_set(hm, "age", 31)
print("Updated age: {hm_get(hm, "age")}")

# Delete
hm_delete(hm, "city")
print("After delete 'city': {hm_has(hm, "city")}")
print("Final count: {hm.count}")
