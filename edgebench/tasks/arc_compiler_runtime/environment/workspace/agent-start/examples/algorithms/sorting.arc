# Advanced Sorting Algorithms
# Demonstrates: recursion, mutation, pipelines

# Bubble sort
fn bubble_sort(arr) {
  let mut lst = arr
  let n = len(lst)
  for i in 0..n {
    for j in 0..(n-i-1) {
      if lst[j] > lst[j+1] {
        let temp = lst[j]
        lst[j] = lst[j+1]
        lst[j+1] = temp
      }
    }
  }
  lst
}

# Selection sort
fn selection_sort(arr) {
  let mut lst = arr
  let n = len(lst)
  for i in 0..n {
    let mut min_idx = i
    for j in (i+1)..n {
      if lst[j] < lst[min_idx] {
        min_idx = j
      }
    }
    if min_idx != i {
      let temp = lst[i]
      lst[i] = lst[min_idx]
      lst[min_idx] = temp
    }
  }
  lst
}

# Counting sort (for positive integers)
fn counting_sort(arr) {
  if len(arr) == 0 { ret [] }
  let mx = arr |> reduce((a, b) => max(a, b), 0)
  let mut count = [0 for _ in 0..(mx+1)]
  for x in arr {
    count[x] = count[x] + 1
  }
  let mut result = []
  for i in 0..(mx+1) {
    for _ in 0..(count[i]) {
      result = push(result, i)
    }
  }
  result
}

# Test
print("=== Advanced Sorting ===")
let data = [64, 34, 25, 12, 22, 11, 90]

print("Original: {data}")
print("Bubble:   {bubble_sort(data)}")
print("Select:   {selection_sort(data)}")

let int_data = [4, 2, 2, 8, 3, 3, 1]
print("Counting: {counting_sort(int_data)}")

# Performance comparison (small dataset)
let big = [38, 27, 43, 3, 9, 82, 10, 1, 45, 76, 23, 67, 54, 31, 88]
let t1 = time_ms()
let r1 = bubble_sort(big)
let t2 = time_ms()
let r2 = selection_sort(big)
let t3 = time_ms()

print("\nBubble sort result: {r1}")
print("Selection sort result: {r2}")
print("Bubble time: {t2 - t1}ms")
print("Selection time: {t3 - t2}ms")
