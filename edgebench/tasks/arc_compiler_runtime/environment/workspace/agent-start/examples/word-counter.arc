# Word Frequency Counter
# Demonstrates: maps, pipelines, string operations, comprehensions

let text = "the quick brown fox jumps over the lazy dog the fox the dog"

# Split, normalize, count
let words = text |> split(" ") |> map(lower)

let mut counts = {}
for w in words {
  let cur = if counts[w] != nil { counts[w] } el { 0 }
  counts[w] = cur + 1
}

print("Word frequencies:")
let ks = keys(counts)
for k in ks {
  let v = counts[k]
  let bar = repeat("#", v)
  print("  {k}: {v} {bar}")
}

# Unique word count
let unique = counts |> keys |> len
print("Unique words: {unique}")
print("Total words: {len(words)}")
