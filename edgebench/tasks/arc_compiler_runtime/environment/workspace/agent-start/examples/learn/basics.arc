# Learn Arc: Basics
# Extracted from Tutorial 1 — variables, types, collections, control flow

# --- Variables ---
let name = "Arc"
let version = 1
let pi = 3.14159

let mut count = 0
count = count + 1
count = count + 1
print(count)    # 2

# --- Destructuring ---
let {name, age} = {name: "Alice", age: 30}
print(name)    # "Alice"

let [first, second, ...rest] = [1, 2, 3, 4, 5]
print(first)   # 1
print(rest)    # [3, 4, 5]

# --- Semantic Types ---
type Email = String matching /^[^@]+@[^@]+\.[^@]+$/
type Age = Int where x => x >= 0 and x <= 150

# --- String Interpolation ---
let x = 7
print("Hello, {name}!")          # Hello, Alice!
print("7 * 6 = {x * 6}")        # 7 * 6 = 42

# --- String Operations ---
let s = "Hello, World!"
len(s)          # 13
upper(s)        # "HELLO, WORLD!"
split(s, ", ")  # ["Hello", "World!"]
"Hello" ++ " " ++ "World"   # "Hello World"

# --- Lists ---
let numbers = [1, 2, 3, 4, 5]
len(numbers)              # 5
push(numbers, 6)          # [1, 2, 3, 4, 5, 6]
let combined = [1, 2] ++ [3, 4]  # [1, 2, 3, 4]
reverse(numbers)          # [5, 4, 3, 2, 1]
sort([3, 1, 4, 1, 5])    # [1, 1, 3, 4, 5]

# --- Comprehensions ---
let squares = [x * x for x in 1..6]          # [1, 4, 9, 16, 25]
let evens = [x for x in 1..11 if x % 2 == 0]  # [2, 4, 6, 8, 10]

# --- Maps ---
let user = {name: "Alice", age: 30, active: true}
user.name       # "Alice"
keys(user)      # ["name", "age", "active"]

# --- Control Flow ---
let status = if count > 0 { "active" } el { "empty" }

for i in 1..4 {
  print("Count: {i}")
}

# --- Processing Example ---
let nums = [4, -2, 7, 0, -1, 3, 8]
let positives = nums |> filter(x => x > 0)
let total = positives |> reduce((sum, x) => sum + x, 0)
print("Found {len(positives)} positives, sum = {total}")
