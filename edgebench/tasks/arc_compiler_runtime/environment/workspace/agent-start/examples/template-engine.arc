# Template Engine
# Demonstrates: string parsing, recursion, maps, pipelines

fn render(template, data) {
  let chs = chars(template)
  let mut result = ""
  let mut i = 0
  let n = len(chs)
  let open_brace = "\{"
  let close_brace = "\}"

  for _ in 0..n {
    if i >= n { ret result }

    if chs[i] == open_brace and i + 1 < n and chs[i + 1] == open_brace {
      # Found {{ — extract variable name
      i = i + 2
      let mut var_name = ""
      for _ in 0..n {
        if i >= n { ret result ++ "\{\{" ++ var_name }
        if chs[i] == close_brace and i + 1 < n and chs[i + 1] == close_brace {
          i = i + 2
          let value = data[trim(var_name)]
          result = result ++ if value != nil { str(value) } el { "\{\{" ++ var_name ++ "\}\}" }
          ret result ++ render(slice(template, i, n), data)
        }
        var_name = var_name ++ chs[i]
        i = i + 1
      }
    } el {
      result = result ++ chs[i]
      i = i + 1
    }
  }
  result
}

fn render_list(template, items) {
  let mut result = []
  for item in items {
    result = push(result, render(template, item))
  }
  result |> join("\n")
}

# Demo
print("=== Template Engine ===")

let tmpl = "Hello, \{\{name\}\}! You are \{\{age\}\} years old."
let data = {name: "Alice", age: 30}
print(render(tmpl, data))

let email_tmpl = "Dear \{\{name\}\},\nYour order #\{\{order_id\}\} has been \{\{status\}\}.\nThank you!"
let order = {name: "Bob", order_id: 12345, status: "shipped"}
print("")
print(render(email_tmpl, order))

# Render a list
print("")
let item_tmpl = "- \{\{name\}\}: $\{\{price\}\}"
let items = [
  {name: "Widget", price: 9.99},
  {name: "Gadget", price: 24.99},
  {name: "Doohickey", price: 14.99}
]
print("Shopping List:")
print(render_list(item_tmpl, items))

# Missing variables stay as-is
let partial = render("Hello \{\{name\}\}, your code is \{\{code\}\}", {name: "Charlie"})
print("")
print("Partial: {partial}")
