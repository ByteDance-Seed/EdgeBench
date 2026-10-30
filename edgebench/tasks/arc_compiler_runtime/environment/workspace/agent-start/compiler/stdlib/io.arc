# Arc Standard Library: io module
# File I/O utilities (operates on strings/lists; actual I/O via prelude read/write)

pub fn read_lines(path) {
  let content = read(path)
  if content == nil { [] }
  el { split(content, "\n") }
}

pub fn write_lines(path, lines) {
  let content = join(lines, "\n")
  write(path, content)
}

pub fn exists(path) {
  # Simulated: try reading, return true if non-nil
  let content = read(path)
  content != nil
}

pub fn read_file(path) {
  read(path)
}

pub fn write_file(path, content) {
  write(path, content)
}

pub fn append(path, data) {
  let existing = read(path)
  if existing == nil {
    write(path, str(data))
  } el {
    write(path, existing ++ str(data))
  }
}
