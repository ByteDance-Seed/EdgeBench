# Dynamic Programming
# Demonstrates: recursion, memoization, mutation, maps

# Fibonacci with memoization
let mut fib_cache = {0: 0, 1: 1}
fn fib(n) {
  if fib_cache[n] != nil { ret fib_cache[n] }
  let result = fib(n - 1) + fib(n - 2)
  fib_cache[n] = result
  result
}

print("=== Dynamic Programming ===")
print("Fibonacci(20): {fib(20)}")
print("Fibonacci(30): {fib(30)}")

# Longest Common Subsequence
fn lcs(a, b) {
  let m = len(a)
  let n = len(b)
  # Build DP table
  let mut dp = []
  for i in 0..(m+1) {
    let mut row = []
    for j in 0..(n+1) {
      row = push(row, 0)
    }
    dp = push(dp, row)
  }

  for i in 1..(m+1) {
    for j in 1..(n+1) {
      if a[i-1] == b[j-1] {
        dp[i][j] = dp[i-1][j-1] + 1
      } el {
        dp[i][j] = max(dp[i-1][j], dp[i][j-1])
      }
    }
  }
  dp[m][n]
}

let a = chars("ABCBDAB")
let b = chars("BDCAB")
print("LCS of ABCBDAB and BDCAB: {lcs(a, b)}")

# Coin Change (minimum coins)
fn min_coins(coins, amount) {
  let mut dp = [amount + 1 for _ in 0..(amount+1)]
  dp[0] = 0

  for i in 1..(amount+1) {
    for coin in coins {
      if coin <= i {
        let candidate = dp[i - coin] + 1
        if candidate < dp[i] {
          dp[i] = candidate
        }
      }
    }
  }

  if dp[amount] > amount { -1 } el { dp[amount] }
}

print("Min coins for 11 (coins=[1,5,6]): {min_coins([1, 5, 6], 11)}")
print("Min coins for 15 (coins=[1,5,10]): {min_coins([1, 5, 10], 15)}")

# Knapsack 0/1
fn knapsack(weights, values, capacity) {
  let n = len(weights)
  let mut dp = []
  for i in 0..(n+1) {
    let mut row = [0 for _ in 0..(capacity+1)]
    dp = push(dp, row)
  }

  for i in 1..(n+1) {
    for w in 0..(capacity+1) {
      if weights[i-1] <= w {
        let with_item = values[i-1] + dp[i-1][w - weights[i-1]]
        let without_item = dp[i-1][w]
        dp[i][w] = max(with_item, without_item)
      } el {
        dp[i][w] = dp[i-1][w]
      }
    }
  }
  dp[n][capacity]
}

let w = [2, 3, 4, 5]
let v = [3, 4, 5, 6]
print("Knapsack (cap=8): {knapsack(w, v, 8)}")

