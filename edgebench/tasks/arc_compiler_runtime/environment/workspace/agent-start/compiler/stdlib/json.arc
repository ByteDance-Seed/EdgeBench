# Arc Standard Library: json module
# JSON utilities (pure string manipulation)
#
# Note: Arc's lexer treats { inside strings as interpolation.
# We construct brace characters at runtime from str({}).

# Module-level brace chars
let _LB = slice(str({}), 0, 1)
let _RB = slice(str({}), 1, 2)
let _Q = chars("\"")[0]

pub fn to_json(value) {
  let t = type_of(value)
  if t == "nil" { "null" }
  el if t == "bool" { if value { "true" } el { "false" } }
  el if t == "int" { str(value) }
  el if t == "float" {
    let s = str(value)
    if s == "Infinity" or s == "-Infinity" or s == "NaN" { "null" }
    el { s }
  }
  el if t == "string" { _quote(value) }
  el if t == "list" {
    "[" ++ join(map(value, v => to_json(v)), ",") ++ "]"
  }
  el if t == "map" {
    let ks = keys(value)
    let pairs = map(ks, k => _quote(k) ++ ":" ++ to_json(value[k]))
    _LB ++ join(pairs, ",") ++ _RB
  }
  el { str(value) }
}

fn _quote(s) {
  let escaped = replace(replace(s, "\\", "\\\\"), "\n", "\\n")
  let escaped = replace(escaped, "\t", "\\t")
  let escaped = replace(escaped, "\r", "\\r")
  let escaped = replace(escaped, "\"", "\\\"")
  _Q ++ escaped ++ _Q
}

pub fn from_json(s) {
  let trimmed = trim(s)
  if len(trimmed) == 0 { error_throw("Invalid JSON: empty string") }
  el {
    let parsed = _parse_value(trimmed)
    if parsed == nil { error_throw("Invalid JSON: " ++ s) }
    el if len(trim(parsed.rest)) > 0 { error_throw("Invalid JSON: unexpected trailing content") }
    el { parsed.value }
  }
}

fn _parse_value(s) {
  let c = slice(s, 0, 1)
  if c == _Q { _parse_string(s) }
  el if c == "[" { _parse_array(s) }
  el if c == _LB { _parse_object(s) }
  el if c == "t" { _mk(true, slice(s, 4, len(s))) }
  el if c == "f" { _mk(false, slice(s, 5, len(s))) }
  el if c == "n" { _mk(nil, slice(s, 4, len(s))) }
  el { _parse_number(s) }
}

fn _mk(v, r) {
  let mut result = {}
  result["value"] = v
  result["rest"] = r
  result
}

fn _parse_string(s) {
  let mut i = 1
  let mut result = ""
  let mut done = false
  let mut escaped = false
  do {
    let ch = slice(s, i, i + 1)
    if escaped {
      if ch == "n" { result = result ++ "\n" }
      el if ch == "t" { result = result ++ "\t" }
      el if ch == "u" {
        let hex = slice(s, i + 1, i + 5)
        i = i + 4
        result = result ++ __native("json.from_codepoint", hex)
      }
      el { result = result ++ ch }
      escaped = false
    } el if ch == "\\" {
      escaped = true
    } el if ch == _Q {
      done = true
    } el {
      result = result ++ ch
    }
    i = i + 1
  } until done
  _mk(result, trim(slice(s, i, len(s))))
}

fn _parse_number(s) {
  let mut i = 0
  let mut is_float = false
  if slice(s, 0, 1) == "-" { i = 1 }
  do {
    let ch = slice(s, i, i + 1)
    if ch == "." or ch == "e" or ch == "E" { is_float = true }
    i = i + 1
  } until i >= len(s) or not _is_num_char(slice(s, i, i + 1))
  let num_str = slice(s, 0, i)
  let value = if is_float { float(num_str) } el { int(num_str) }
  _mk(value, trim(slice(s, i, len(s))))
}

fn _is_num_char(c) {
  c == "0" or c == "1" or c == "2" or c == "3" or c == "4" or
  c == "5" or c == "6" or c == "7" or c == "8" or c == "9" or
  c == "." or c == "-" or c == "e" or c == "E" or c == "+"
}

fn _parse_array(s) {
  let mut rest = trim(slice(s, 1, len(s)))
  let mut items = []
  if slice(rest, 0, 1) == "]" {
    _mk(items, trim(slice(rest, 1, len(rest))))
  } el {
    let mut done = false
    do {
      let parsed = _parse_value(rest)
      items = push(items, parsed.value)
      rest = trim(parsed.rest)
      let next = slice(rest, 0, 1)
      if next == "," {
        rest = trim(slice(rest, 1, len(rest)))
      } el {
        done = true
      }
    } until done
    rest = trim(slice(rest, 1, len(rest)))
    _mk(items, rest)
  }
}

fn _parse_object(s) {
  let mut rest = trim(slice(s, 1, len(s)))
  let mut obj = {}
  if slice(rest, 0, 1) == _RB {
    _mk(obj, trim(slice(rest, 1, len(rest))))
  } el {
    let mut done = false
    do {
      let key_parsed = _parse_string(rest)
      rest = trim(key_parsed.rest)
      rest = trim(slice(rest, 1, len(rest)))
      let val_parsed = _parse_value(rest)
      obj[key_parsed.value] = val_parsed.value
      rest = trim(val_parsed.rest)
      let next = slice(rest, 0, 1)
      if next == "," {
        rest = trim(slice(rest, 1, len(rest)))
      } el {
        done = true
      }
    } until done
    rest = trim(slice(rest, 1, len(rest)))
    _mk(obj, rest)
  }
}

pub fn pretty(value) {
  _pretty_indent(value, 0)
}

fn _pretty_indent(value, depth) {
  let indent = repeat("  ", depth)
  let inner = repeat("  ", depth + 1)
  let t = type_of(value)
  if t == "map" {
    let ks = keys(value)
    if len(ks) == 0 { _LB ++ _RB }
    el {
      let pairs = map(ks, k => inner ++ _Q ++ k ++ _Q ++ ": " ++ _pretty_indent(value[k], depth + 1))
      _LB ++ "\n" ++ join(pairs, ",\n") ++ "\n" ++ indent ++ _RB
    }
  }
  el if t == "list" {
    if len(value) == 0 { "[]" }
    el {
      let items = map(value, v => inner ++ _pretty_indent(v, depth + 1))
      "[\n" ++ join(items, ",\n") ++ "\n" ++ indent ++ "]"
    }
  }
  el { to_json(value) }
}

pub fn get_path(obj, path) {
  let parts = split(path, ".")
  let mut current = obj
  for part in parts {
    if type_of(current) == "map" {
      current = current[part]
    } el if type_of(current) == "list" {
      let idx = int(part)
      if idx != nil {
        current = current[idx]
      } el {
        current = nil
      }
    } el {
      current = nil
    }
  }
  current
}
