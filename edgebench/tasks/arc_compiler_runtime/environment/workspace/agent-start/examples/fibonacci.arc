# Fibonacci — Recursive, Iterative, and Memoized
# Demonstrates: recursion, mutability, maps, pattern matching, pipelines

# 1. Simple recursive
fn fib_rec(n) => match n {
  0 => 0,
  1 => 1,
  n => fib_rec(n - 1) + fib_rec(n - 2)
}

# 2. Iterative with mutation
fn fib_iter(n) {
  let mut a = 0
  let mut b = 1
  for _ in 0..n {
    let temp = b
    b = a + b
    a = temp
  }
  a
}

# 3. Memoized with a map
let mut memo = {0: 0, 1: 1}

fn fib_memo(n) {
  if memo[n] != nil { ret memo[n] }
  let result = fib_memo(n - 1) + fib_memo(n - 2)
  memo[n] = result
  result
}

# Run all three
print("Recursive fib(10): {fib_rec(10)}")
print("Iterative fib(10): {fib_iter(10)}")
print("Memoized  fib(10): {fib_memo(10)}")

# Generate a sequence with pipeline
let sequence = 0..15 |> map(fib_iter)
print("First 15: {sequence}")
