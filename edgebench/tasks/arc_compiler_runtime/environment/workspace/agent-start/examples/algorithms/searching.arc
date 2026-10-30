# Searching Algorithms
# Demonstrates: recursion, mutation, pipelines

# Binary search (iterative)
fn binary_search(arr, target) {
  let mut lo = 0
  let mut hi = len(arr) - 1
  for _ in 0..len(arr) {
    if lo > hi { ret -1 }
    let mid = (lo + hi) / 2
    if arr[mid] == target { ret mid }
    if arr[mid] < target {
      lo = mid + 1
    } el {
      hi = mid - 1
    }
  }
  -1
}

# Binary search (recursive)
fn binary_search_rec(arr, target, lo, hi) {
  if lo > hi { ret -1 }
  let mid = (lo + hi) / 2
  if arr[mid] == target { ret mid }
  if arr[mid] < target {
    binary_search_rec(arr, target, mid + 1, hi)
  } el {
    binary_search_rec(arr, target, lo, mid - 1)
  }
}

# Linear search
fn linear_search(arr, target) {
  for i in 0..len(arr) {
    if arr[i] == target { ret i }
  }
  -1
}

# Interpolation search (for uniformly distributed data)
fn interpolation_search(arr, target) {
  let mut lo = 0
  let mut hi = len(arr) - 1
  for _ in 0..len(arr) {
    if lo > hi { ret -1 }
    if arr[lo] == arr[hi] {
      if arr[lo] == target { ret lo } el { ret -1 }
    }
    let pos = lo + ((target - arr[lo]) * (hi - lo)) / (arr[hi] - arr[lo])
    if pos < lo or pos > hi { ret -1 }
    if arr[pos] == target { ret pos }
    if arr[pos] < target { lo = pos + 1 }
    el { hi = pos - 1 }
  }
  -1
}

# Test
print("=== Searching Algorithms ===")
let data = [2, 5, 8, 12, 16, 23, 38, 45, 56, 72, 91]

print("Data: {data}")
print("")

let targets = [23, 5, 91, 100, 2]
for target in targets {
  let idx1 = binary_search(data, target)
  let idx2 = binary_search_rec(data, target, 0, len(data) - 1)
  let idx3 = linear_search(data, target)

  let found = if idx1 >= 0 { "found at index {idx1}" } el { "not found" }
  print("Search {target}: {found}")
}

# Search in strings
let names = ["Alice", "Bob", "Charlie", "Diana", "Eve"]
let sorted_names = sort(names)
print("\nSorted names: {sorted_names}")
let idx = linear_search(sorted_names, "Charlie")
print("Charlie at index: {idx}")
