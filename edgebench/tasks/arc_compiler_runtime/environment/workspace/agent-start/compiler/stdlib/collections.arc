# Arc Standard Library: collections module
# Advanced collection utilities

pub fn set(list) {
  let mut result = []
  for item in list {
    if not contains(result, item) {
      result = push(result, item)
    }
  }
  result
}

pub fn unique(list) => set(list)

pub fn group_by(list, f) {
  let mut result = {}
  for item in list {
    let key = str(f(item))
    let existing = if contains(keys(result), key) { result[key] } el { [] }
    result[key] = push(existing, item)
  }
  result
}

pub fn count_by(list, f) {
  let mut result = {}
  for item in list {
    let key = str(f(item))
    let existing = if contains(keys(result), key) { result[key] } el { 0 }
    result[key] = existing + 1
  }
  result
}

pub fn chunk(list, size) {
  if size <= 0 { [] }
  el if len(list) == 0 { [] }
  el {
    let mut result = []
    let mut i = 0
    do {
      let end = if i + size > len(list) { len(list) } el { i + size }
      result = push(result, slice(list, i, end))
      i = i + size
    } until i >= len(list)
    result
  }
}

pub fn flatten(list) => flat(list)

pub fn zip_with(a, b, f) {
  let mut result = []
  let pairs = zip(a, b)
  for p in pairs {
    result = push(result, f(p[0], p[1]))
  }
  result
}

pub fn partition(list, f) {
  let passing = filter(list, f)
  let not_f = x => not f(x)
  let failing = filter(list, not_f)
  let result = [passing, failing]
  result
}

pub fn frequencies(list) {
  let mut result = {}
  for item in list {
    let key = str(item)
    let existing = if contains(keys(result), key) { result[key] } el { 0 }
    result[key] = existing + 1
  }
  result
}

pub fn min_by(list, f) {
  if len(list) == 0 { nil }
  el {
    let mut best = list[0]
    let mut best_val = f(best)
    for i in 1..len(list) {
      let val = f(list[i])
      if val < best_val {
        best = list[i]
        best_val = val
      }
    }
    best
  }
}

pub fn max_by(list, f) {
  if len(list) == 0 { nil }
  el {
    let mut best = list[0]
    let mut best_val = f(best)
    for i in 1..len(list) {
      let val = f(list[i])
      if val > best_val {
        best = list[i]
        best_val = val
      }
    }
    best
  }
}

pub fn sort_by(list, f) {
  # sort_by takes a key function fn(x), not a comparator fn(a, b)
  assert(arity(f) == 1, "sort_by takes a key function fn(x) that returns a sort key, not a comparator fn(a, b). Example: sort_by(list, fn(x) => x.name)")
  let mut arr = map(list, x => x)
  for i in 1..len(arr) {
    let mut j = i
    do {
      if j <= 0 { j = 0 }
      el if f(arr[j]) < f(arr[j - 1]) {
        let tmp = arr[j]
        arr[j] = arr[j - 1]
        arr[j - 1] = tmp
        j = j - 1
      } el { j = 0 }
    } until j <= 0
  }
  arr
}

pub fn index_of(list, val) {
  let mut result = nil
  for i in 0..len(list) {
    if list[i] == val and result == nil {
      result = i
    }
  }
  result
}

pub fn includes(list, val) => contains(list, val)
