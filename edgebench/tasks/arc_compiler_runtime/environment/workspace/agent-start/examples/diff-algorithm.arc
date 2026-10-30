# Diff Algorithm (Simplified LCS-based)
# Demonstrates: dynamic programming, string processing, pipelines

fn lcs_table(a, b) {
  let m = len(a)
  let n = len(b)
  let mut dp = []
  for i in 0..(m+1) {
    dp = push(dp, [0 for _ in 0..(n+1)])
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
  dp
}

fn compute_diff(old_lines, new_lines) {
  let dp = lcs_table(old_lines, new_lines)
  let mut diff = []
  let mut i = len(old_lines)
  let mut j = len(new_lines)

  for _ in 0..(len(old_lines) + len(new_lines) + 1) {
    if i == 0 and j == 0 { ret reverse(diff) }
    if i > 0 and j > 0 and old_lines[i-1] == new_lines[j-1] {
      diff = push(diff, {kind: "same", text: old_lines[i-1]})
      i = i - 1
      j = j - 1
    } el if j > 0 and (i == 0 or dp[i][j-1] >= dp[i-1][j]) {
      diff = push(diff, {kind: "add", text: new_lines[j-1]})
      j = j - 1
    } el if i > 0 {
      diff = push(diff, {kind: "del", text: old_lines[i-1]})
      i = i - 1
    }
  }
  reverse(diff)
}

fn display_diff(diff) {
  for entry in diff {
    let prefix = match entry.kind {
      "add" => "+ ",
      "del" => "- ",
      _ => "  "
    }
    print("{prefix}{entry.text}")
  }
}

fn diff_stats(diff) {
  let added = diff |> filter(d => d.kind == "add") |> len
  let deleted = diff |> filter(d => d.kind == "del") |> len
  let same = diff |> filter(d => d.kind == "same") |> len
  {added: added, deleted: deleted, unchanged: same}
}

# Demo
print("=== Diff Algorithm ===")

let old_lines = ["fn hello() \{", "  print(\"Hello\")", "  print(\"World\")", "  ret 0", "\}"]

let new_lines = ["fn hello() \{", "  print(\"Hello, Arc!\")", "  print(\"World\")", "  let x = 42", "  ret x", "\}"]

let old_text = old_lines
let new_text = new_lines

let diff = compute_diff(old_text, new_text)
display_diff(diff)

let stats = diff_stats(diff)
print("")
print("Stats: +{stats.added} -{stats.deleted} ~{stats.unchanged}")

