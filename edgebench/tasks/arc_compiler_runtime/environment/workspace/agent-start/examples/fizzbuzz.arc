# FizzBuzz — The Arc Way
# Demonstrates: pipelines, pattern matching, ranges, comprehensions

fn fizzbuzz(n) => match [n % 3, n % 5] {
  [0, 0] => "FizzBuzz",
  [0, _] => "Fizz",
  [_, 0] => "Buzz",
  _ => "{n}"
}

# Pipeline approach: generate, transform, print
let results = 1..101 |> map(fizzbuzz)
for r in results {
  print(r)
}

# Comprehension approach (one-liner)
let all = [fizzbuzz(n) for n in 1..101]
print(all)
