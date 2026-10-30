# Arc Standard Library: strings module

pub fn pad_left(s, width, ch) {
  let mut result = str(s)
  if len(str(ch)) == 0 { result }
  el {
    let pad_char = slice(str(ch), 0, 1)
    if len(result) >= width { result }
    el {
      do {
        result = pad_char ++ result
      } until len(result) >= width
      result
    }
  }
}

pub fn pad_right(s, width, ch) {
  let mut result = str(s)
  if len(str(ch)) == 0 { result }
  el {
    let pad_char = slice(str(ch), 0, 1)
    if len(result) >= width { result }
    el {
      do {
        result = result ++ pad_char
      } until len(result) >= width
      result
    }
  }
}

pub fn capitalize(s) {
  if len(s) == 0 { "" }
  el {
    let first = upper(slice(s, 0, 1))
    let rest = lower(slice(s, 1, len(s)))
    first ++ rest
  }
}

pub fn words(s) {
  split(trim(s), " ") |> filter(w => len(w) > 0)
}
