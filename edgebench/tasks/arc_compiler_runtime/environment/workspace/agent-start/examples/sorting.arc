# Sorting Algorithms in Arc
# Demonstrates: recursion, pattern matching, list operations, pipelines

# Quicksort
fn quicksort(lst) {
  if len(lst) <= 1 { ret lst }
  let pivot = head(lst)
  let rest = tail(lst)
  let lo = [x for x in rest if x < pivot]
  let hi = [x for x in rest if x >= pivot]
  quicksort(lo) ++ [pivot] ++ quicksort(hi)
}

# Mergesort
fn merge(a, b) {
  if len(a) == 0 { ret b }
  if len(b) == 0 { ret a }
  let x = head(a)
  let y = head(b)
  if x <= y {
    [x] ++ merge(tail(a), b)
  } el {
    [y] ++ merge(a, tail(b))
  }
}

fn mergesort(lst) {
  if len(lst) <= 1 { ret lst }
  let mid = len(lst) / 2
  let left = lst |> take(mid)
  let right = lst |> drop(mid)
  merge(mergesort(left), mergesort(right))
}

# Insertion sort using fold
fn insert_sorted(x, sorted) {
  if len(sorted) == 0 { ret [x] }
  let h = head(sorted)
  if x <= h { [x] ++ sorted } el { [h] ++ insert_sorted(x, tail(sorted)) }
}

fn insertion_sort(lst) {
  let mut result = []
  for x in lst {
    result = insert_sorted(x, result)
  }
  result
}

# Test them all
let data = [38, 27, 43, 3, 9, 82, 10]
print("Original:  {data}")
print("Quicksort: {quicksort(data)}")
print("Mergesort: {mergesort(data)}")
print("Insertion: {insertion_sort(data)}")

# Sort strings too
let words = ["banana", "apple", "cherry", "date"]
print("Sorted words: {quicksort(words)}")
