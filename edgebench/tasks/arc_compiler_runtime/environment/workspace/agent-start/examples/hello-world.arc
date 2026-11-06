# Hello World in Arc

let name = "World"
print("Hello, {name}!")

# Basic math
fn add(a, b) => a + b
let result = add(3, 4)
print("3 + 4 = {result}")

# Lists and pipelines
let numbers = [1, 2, 3, 4, 5]
let doubled = numbers |> map(x => x * 2)
print("Doubled: {doubled}")

let total = numbers |> sum
print("Sum: {total}")

# Pattern matching
fn describe(n) => match n {
  0 => "zero",
  1 => "one",
  _ => "many"
}

print(describe(0))
print(describe(1))
print(describe(42))

# If/el expressions
let x = 10
let label = if x > 5 { "big" } el { "small" }
print("x is {label}")

# String ops
let greeting = "hello" ++ " " ++ "world"
print(greeting)

# For loop
for i in [1, 2, 3] {
  print("item: {i}")
}
