# Min Heap / Priority Queue
# Demonstrates: array-based tree, mutation, pipelines

fn new_heap() => {data: []}

fn heap_parent(i) => (i - 1) / 2
fn heap_left(i) => 2 * i + 1
fn heap_right(i) => 2 * i + 2

fn heap_swap(arr, i, j) {
  let temp = arr[i]
  arr[i] = arr[j]
  arr[j] = temp
}

fn heap_push(h, value) {
  h.data = push(h.data, value)
  # Sift up
  let mut i = len(h.data) - 1
  for _ in 0..len(h.data) {
    if i <= 0 { ret nil }
    let p = heap_parent(i)
    if h.data[i] < h.data[p] {
      heap_swap(h.data, i, p)
      i = p
    } el {
      ret nil
    }
  }
}

fn heap_pop(h) {
  if len(h.data) == 0 { ret nil }
  let result = h.data[0]
  let last_val = last(h.data)
  h.data = take(h.data, len(h.data) - 1)
  if len(h.data) == 0 { ret result }
  h.data[0] = last_val

  # Sift down
  let mut i = 0
  let n = len(h.data)
  for _ in 0..n {
    let l = heap_left(i)
    let r = heap_right(i)
    let mut smallest = i
    if l < n and h.data[l] < h.data[smallest] { smallest = l }
    if r < n and h.data[r] < h.data[smallest] { smallest = r }
    if smallest != i {
      heap_swap(h.data, i, smallest)
      i = smallest
    } el {
      ret result
    }
  }
  result
}

fn heap_peek(h) {
  if len(h.data) == 0 { nil } el { h.data[0] }
}

fn heap_size(h) => len(h.data)

# Heap sort using our heap
fn heap_sort(arr) {
  let mut h = new_heap()
  for x in arr { heap_push(h, x) }
  let mut result = []
  for _ in 0..len(arr) {
    result = push(result, heap_pop(h))
  }
  result
}

# Demo
print("=== Heap / Priority Queue ===")

let mut h = new_heap()
let values = [5, 3, 8, 1, 9, 2, 7, 4, 6]

print("Inserting: {values}")
for v in values { heap_push(h, v) }

print("Peek (min): {heap_peek(h)}")
print("Size: {heap_size(h)}")

print("\nPopping all (should be sorted):")
let mut sorted = []
for _ in 0..len(values) {
  let v = heap_pop(h)
  sorted = push(sorted, v)
}
print("Result: {sorted}")

# Heap sort
let data = [38, 27, 43, 3, 9, 82, 10]
print("\nHeap sort: {heap_sort(data)}")
