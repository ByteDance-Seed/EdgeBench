use toml

let input = "[package]
name = \"arc-lang\"
version = \"1.0.0\"
authors = [\"Alice\", \"Bob\"]

[database]
host = \"localhost\"
port = 5432
enabled = true

[[servers]]
name = \"alpha\"
ip = \"10.0.0.1\"

[[servers]]
name = \"beta\"
ip = \"10.0.0.2\""

let parsed = toml.parse(input)
print("=== TOML Parse ===")
print(parsed)
print("package name: " ++ str(parsed["package"]["name"]))
print("package version: " ++ str(parsed["package"]["version"]))
print("authors: " ++ str(parsed["package"]["authors"]))
print("db host: " ++ str(parsed["database"]["host"]))
print("db port: " ++ str(parsed["database"]["port"]))
print("db enabled: " ++ str(parsed["database"]["enabled"]))
print("servers: " ++ str(parsed["servers"]))

print("")
print("=== TOML Stringify ===")
let output = toml.stringify(parsed)
print(output)
