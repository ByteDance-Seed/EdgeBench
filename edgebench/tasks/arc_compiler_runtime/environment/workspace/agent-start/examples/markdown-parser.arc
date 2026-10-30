# Markdown Parser (Subset)
# Demonstrates: string parsing, pattern matching, recursion, pipelines

fn parse_line(line) {
  if starts(line, "### ") { {kind: "h3", text: slice(line, 4, len(line))} }
  el if starts(line, "## ") { {kind: "h2", text: slice(line, 3, len(line))} }
  el if starts(line, "# ") { {kind: "h1", text: slice(line, 2, len(line))} }
  el if starts(line, "- ") { {kind: "li", text: slice(line, 2, len(line))} }
  el if starts(line, "> ") { {kind: "quote", text: slice(line, 2, len(line))} }
  el if starts(line, "---") { {kind: "hr", text: ""} }
  el if line == "" { {kind: "blank", text: ""} }
  el { {kind: "p", text: line} }
}

fn to_html(node) => match node.kind {
  "h1" => "<h1>{node.text}</h1>",
  "h2" => "<h2>{node.text}</h2>",
  "h3" => "<h3>{node.text}</h3>",
  "p" => "<p>{node.text}</p>",
  "li" => "<li>{node.text}</li>",
  "quote" => "<blockquote>{node.text}</blockquote>",
  "hr" => "<hr>",
  "blank" => "",
  _ => node.text
}

fn parse_markdown(text) {
  let lines = split(text, "\n")
  let result = map(lines, parse_line)
  result
}

fn render_html(nodes) {
  nodes
    |> map(to_html)
    |> filter(s => s != "")
    |> join("\n")
}

# Demo
print("=== Markdown Parser ===")

let markdown = "# Hello World\nThis is a paragraph.\n\n## Features\n- Fast parsing\n- Clean output\n- Pipeline-based\n\n> This is a quote\n\n---\n\n### Details\nAnother paragraph here."

let nodes = parse_markdown(markdown)
print("Parsed {len(nodes)} nodes:")
for node in nodes {
  if node.kind != "blank" {
    print("  [{node.kind}] {node.text}")
  }
}

print("")
print("HTML output:")
print(render_html(nodes))
