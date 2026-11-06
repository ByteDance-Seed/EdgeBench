# Data processing with pipelines

let data = [5, 3, 8, 1, 9, 2, 7, 4, 6]

# Filter and transform
let result = data
  |> filter(x => x > 3)
  |> map(x => x * 10)
  |> sort

print("Processed: {result}")

# Aggregation
let total = data |> sum
let count = data |> len
print("Sum: {total}, Count: {count}")

# List comprehension
let squares = [x * x for x in data if x > 3]
print("Squares of >3: {squares}")

# String processing
let words = "hello world foo bar"
let upper_words = words |> split(" ") |> map(w => upper(w)) |> join(", ")
print("Upper: {upper_words}")

# Take and drop
let first3 = data |> sort |> take(3)
let last3 = data |> sort |> drop(6)
print("First 3: {first3}")
print("Last 3: {last3}")
