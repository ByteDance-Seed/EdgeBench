use yaml

let input = "name: Arc Language
version: 1.0
debug: true
count: 42
database:
  host: localhost
  port: 5432
tags:
  - fast
  - simple
  - fun"

let parsed = yaml.parse(input)
print("=== YAML Parse ===")
print(parsed)
print("name: " ++ str(parsed["name"]))
print("version: " ++ str(parsed["version"]))
print("debug: " ++ str(parsed["debug"]))
print("db host: " ++ str(parsed["database"]["host"]))
print("db port: " ++ str(parsed["database"]["port"]))
print("tags: " ++ str(parsed["tags"]))

print("")
print("=== YAML Stringify ===")
let output = yaml.stringify(parsed)
print(output)
