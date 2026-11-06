# Arc Standard Library: math module

# === Constants ===
pub let PI = 3.141592653589793
pub let E = 2.718281828459045
pub let TAU = 6.283185307179586
# INF and NAN available via native runtime

# === Basic ===
pub fn abs(x) => if x < 0 { 0 - x } el { x }

pub fn sign(x) {
  if x > 0 { 1 }
  el if x < 0 { -1 }
  el { 0 }
}

pub fn clamp(x, lo, hi) {
  if x < lo { lo }
  el if x > hi { hi }
  el { x }
}

# === Rounding ===
pub fn ceil(x) => __native("math.ceil", x)

pub fn floor(x) => int(x)

pub fn round(x) => int(x + 0.5)

# === Powers & Roots ===
pub fn pow(base, exp) {
  if exp == 0 { 1 }
  el if exp < 0 and base == 0 { nil }
  el if type_of(exp) == "float" { __native("math.pow", base, exp) }
  el if exp < 0 { 1.0 / pow(base, 0 - exp) }
  el {
    let mut result = 1
    let mut b = base
    let mut e = exp
    do {
      if e % 2 == 1 { result = result * b }
      e = int(e / 2)
      b = b * b
    } until e == 0
    result
  }
}

pub fn sqrt(x) {
  if x == 0 { 0.0 }
  el if x < 0 { nil }
  el {
    let mut guess = x / 2.0
    for i in 0..25 {
      guess = (guess + x / guess) / 2.0
    }
    guess
  }
}

pub fn cbrt(x) => __native("math.cbrt", x)

pub fn hypot(x, y) => __native("math.hypot", x, y)

# === Trigonometry ===
pub fn sin(x) => __native("math.sin", x)
pub fn cos(x) => __native("math.cos", x)
pub fn tan(x) => __native("math.tan", x)
pub fn asin(x) => __native("math.asin", x)
pub fn acos(x) => __native("math.acos", x)
pub fn atan(x) => __native("math.atan", x)
pub fn atan2(y, x) => __native("math.atan2", y, x)

pub fn degrees(rad) => rad * 180.0 / PI
pub fn radians(deg) => deg * PI / 180.0

# === Logarithmic & Exponential ===
pub fn log(x) => __native("math.log", x)
pub fn log2(x) => __native("math.log2", x)
pub fn log10(x) => __native("math.log10", x)
pub fn exp(x) => __native("math.exp", x)

# === Combinatorics ===
pub fn factorial(n) {
  if n < 0 { nil }
  el if n <= 1 { 1 }
  el {
    let mut result = 1
    for i in 2..n + 1 {
      result = result * i
    }
    if str(result) == "Infinity" { nil }
    el { result }
  }
}

pub fn gcd(a, b) {
  let mut x = abs(a)
  let mut y = abs(b)
  if x == 0 and y == 0 { 0 }
  el {
    do {
      let t = y
      y = x % y
      x = t
    } until y == 0
    x
  }
}

pub fn lcm(a, b) {
  let d = gcd(a, b)
  if d == 0 { 0 }
  el { abs(a / d) * b }
}

# === Aggregation ===
pub fn sum(lst) {
  let mut total = 0
  for x in lst {
    if type_of(x) == "int" or type_of(x) == "float" {
      total = total + x
    }
  }
  total
}

pub fn product(lst) {
  let mut total = 1
  for x in lst { total = total * x }
  total
}
