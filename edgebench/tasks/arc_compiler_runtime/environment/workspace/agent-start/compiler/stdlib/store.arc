# Arc Standard Library: store module
# Persistent key-value storage backed by JSON files
#
# Usage:
#   use store
#   let s = store.open("my_data.json")
#   store.set(s, "key", "value")
#   let v = store.get(s, "key")

pub fn open(path) {
  __native("store.open", path)
}

pub fn get(store, key) {
  __native("store.get", store, key)
}

pub fn set(store, key, value) {
  __native("store.set", store, key, value)
}

pub fn delete(store, key) {
  __native("store.delete", store, key)
}

pub fn has(store, key) {
  __native("store.has", store, key)
}

pub fn keys(store) {
  __native("store.keys", store)
}

pub fn values(store) {
  __native("store.values", store)
}

pub fn entries(store) {
  __native("store.entries", store)
}

pub fn clear(store) {
  __native("store.clear", store)
}

pub fn size(store) {
  __native("store.size", store)
}

pub fn merge(store, map) {
  __native("store.merge", store, map)
}

pub fn get_or_set(store, key, default_fn) {
  let existing = get(store, key)
  if existing != nil { existing }
  el {
    let val = default_fn()
    set(store, key, val)
    val
  }
}
