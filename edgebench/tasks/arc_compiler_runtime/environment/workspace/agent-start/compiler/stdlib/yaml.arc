# Arc Standard Library: yaml module
# YAML parsing and stringifying

pub fn parse(text) {
  __native("yaml.parse", text)
}

pub fn stringify(value) {
  __native("yaml.stringify", value)
}
