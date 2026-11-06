# Linked List Implementation
# Demonstrates: recursion, maps as structs, pattern matching, pipelines

fn node(value, next) => {value: value, next: next}

fn prepend(list, value) => node(value, list)

fn ll_len(list) {
  if list == nil { ret 0 }
  ret 1 + ll_len(list.next)
}

fn ll_get(list, index) {
  if list == nil { ret nil }
  if index == 0 { ret list.value }
  ret ll_get(list.next, index - 1)
}

fn ll_append(list, value) {
  if list == nil { ret node(value, nil) }
  ret node(list.value, ll_append(list.next, value))
}

fn ll_reverse(list) {
  fn go(curr, acc) {
    if curr == nil { ret acc }
    ret go(curr.next, node(curr.value, acc))
  }
  ret go(list, nil)
}

fn ll_to_list(ll) {
  if ll == nil { ret [] }
  ret [ll.value] ++ ll_to_list(ll.next)
}

fn ll_from_list(lst) {
  if len(lst) == 0 { ret nil }
  let mut result = nil
  let rev = reverse(lst)
  for item in rev {
    result = prepend(result, item)
  }
  ret result
}

fn ll_map(list, f) {
  if list == nil { ret nil }
  ret node(f(list.value), ll_map(list.next, f))
}

fn ll_filter(list, pred) {
  if list == nil { ret nil }
  if pred(list.value) {
    ret node(list.value, ll_filter(list.next, pred))
  } el {
    ret ll_filter(list.next, pred)
  }
}

# Build and test
print("=== Linked List ===")
let ll = ll_from_list([1, 2, 3, 4, 5])
print("List: {ll_to_list(ll)}")
print("Length: {ll_len(ll)}")
print("Get(2): {ll_get(ll, 2)}")

let ll2 = ll_append(ll, 6)
print("After append 6: {ll_to_list(ll2)}")

let ll3 = prepend(ll, 0)
print("After prepend 0: {ll_to_list(ll3)}")

let ll4 = ll_reverse(ll)
print("Reversed: {ll_to_list(ll4)}")

let doubled = ll_map(ll, x => x * 2)
print("Doubled: {ll_to_list(doubled)}")

let evens = ll_filter(ll, x => x % 2 == 0)
print("Evens: {ll_to_list(evens)}")
