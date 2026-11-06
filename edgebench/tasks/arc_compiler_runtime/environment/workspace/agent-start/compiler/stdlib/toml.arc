# Arc Standard Library: toml module
# TOML parsing and stringifying

pub fn parse(text) {
  __native("toml.parse", text)
}

pub fn stringify(value) {
  __native("toml.stringify", value)
}
