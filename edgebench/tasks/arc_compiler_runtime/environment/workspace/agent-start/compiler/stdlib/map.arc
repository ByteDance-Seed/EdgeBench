# Arc Standard Library: map module
# Map utilities

pub fn merge(a, b) {
  let mut result = {}
  for k in keys(a) {
    result[k] = a[k]
  }
  for k in keys(b) {
    result[k] = b[k]
  }
  result
}

pub fn map_values(m, f) {
  let mut result = {}
  for k in keys(m) {
    result[k] = f(m[k])
  }
  result
}

pub fn map_keys(m, f) {
  let mut result = {}
  for k in keys(m) {
    let new_key = str(f(k))
    result[new_key] = m[k]
  }
  result
}

pub fn filter_map(m, f) {
  let mut result = {}
  for k in keys(m) {
    if f(m[k]) {
      result[k] = m[k]
    }
  }
  result
}

pub fn from_pairs(list) {
  let mut result = {}
  for pair in list {
    result[pair[0]] = pair[1]
  }
  result
}

pub fn to_pairs(m) {
  map(keys(m), k => [k, m[k]])
}

pub fn pick(m, ks) {
  let mut result = {}
  for k in ks {
    if contains(keys(m), k) {
      result[k] = m[k]
    }
  }
  result
}

pub fn omit(m, ks) {
  let mut result = {}
  for k in keys(m) {
    if not contains(ks, k) {
      result[k] = m[k]
    }
  }
  result
}
