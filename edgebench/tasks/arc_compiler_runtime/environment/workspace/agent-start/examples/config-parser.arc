# Config File Parser (INI-style)
# Demonstrates: string parsing, maps, mutation, Result types

fn parse_config(text) {
  let lines = split(text, "\n")
  let mut config = {}
  let mut current_section = "default"
  config[current_section] = {}

  for line in lines {
    let trimmed = trim(line)
    if trimmed == "" or starts(trimmed, "#") or starts(trimmed, ";") {
      # Skip comments and blank lines
    } el if starts(trimmed, "[") and ends(trimmed, "]") {
      # Section header
      current_section = slice(trimmed, 1, len(trimmed) - 1)
      if config[current_section] == nil {
        config[current_section] = {}
      }
    } el if contains(trimmed, "=") {
      let idx = index_of(trimmed, "=")
      let key = trim(slice(trimmed, 0, idx))
      let value = trim(slice(trimmed, idx + 1, len(trimmed)))
      config[current_section][key] = value
    }
  }
  config
}

fn get_config(config, section, key, default_val = nil) {
  if config[section] == nil { ret default_val }
  let val = config[section][key]
  if val == nil { default_val } el { val }
}

fn get_int(config, section, key, default_val = 0) {
  let val = get_config(config, section, key)
  if val == nil { default_val } el { int(val) }
}

fn get_bool(config, section, key, default_val = false) {
  let val = get_config(config, section, key)
  if val == nil { ret default_val }
  val == "true" or val == "1" or val == "yes"
}

fn config_sections(config) => keys(config)

# Demo
print("=== Config Parser ===")

let config_text = "[database]\nhost = localhost\nport = 5432\nname = myapp\nuser = admin\n\n[server]\nhost = 0.0.0.0\nport = 8080\ndebug = true\nworkers = 4\n\n[logging]\nlevel = info\nfile = /var/log/app.log\n\n# This is a comment\n[cache]\nenabled = true\nttl = 3600"

let config = parse_config(config_text)

print("Sections: {config_sections(config)}")
print("DB host: {get_config(config, "database", "host")}")
print("DB port: {get_int(config, "database", "port")}")
print("Server debug: {get_bool(config, "server", "debug")}")
print("Cache TTL: {get_int(config, "cache", "ttl")}")
print("Missing key: {get_config(config, "database", "password", "not-set")}")
print("Log file: {get_config(config, "logging", "file")}")
