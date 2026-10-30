use html

let src = "<div class=\"main\" id=\"app\"><h1>Hello World</h1><p class=\"intro\">This is <b>bold</b> text.</p><br /><p class=\"intro\">Second paragraph</p></div>"

print("=== Parsing HTML ===")
let doc = html.parse(src)
print("Parsed nodes: " ++ str(len(doc)))

# Select by tag
let paragraphs = html.select(doc, "p")
print("\n=== Select <p> tags ===")
print("Found " ++ str(len(paragraphs)) ++ " paragraphs")

# Select by class
let intros = html.select(doc, ".intro")
print("\n=== Select .intro ===")
print("Found " ++ str(len(intros)) ++ " .intro elements")

# Select by id
let app = html.select(doc, "#app")
print("\n=== Select #app ===")
print("Found " ++ str(len(app)) ++ " #app elements")

# Extract text
print("\n=== Text content ===")
for p in paragraphs {
  print("  p text: " ++ html.text(p))
}

# Get attribute
print("\n=== Attributes ===")
let div = app[0]
print("div id: " ++ str(html.attr(div, "id")))
print("div class: " ++ str(html.attr(div, "class")))

# Create a node
print("\n=== Create & Render ===")
let attrs = {}
attrs["class"] = "greeting"
let node = html.create("span", attrs, ["Hi there!"])
print("Rendered: " ++ html.render(node))

# Render back
print("\n=== Round-trip render ===")
print(html.render(doc))
