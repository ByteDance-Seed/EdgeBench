use math

# Constants
assert(math.PI > 3.14, "PI")
assert(math.TAU > 6.28, "TAU")
assert(math.E > 2.71, "E")
assert(math.TAU > math.PI * 1.99, "TAU=2PI")

# Basic
assert(math.abs(-5) == 5, "abs")
assert(math.sign(-3) == -1, "sign neg")
assert(math.sign(7) == 1, "sign pos")
assert(math.sign(0) == 0, "sign zero")
assert(math.clamp(10, 0, 5) == 5, "clamp hi")
assert(math.clamp(-3, 0, 5) == 0, "clamp lo")

# Rounding
assert(math.ceil(2.3) == 3, "ceil")
assert(math.floor(2.9) == 2, "floor")
assert(math.round(2.5) == 3, "round")

# Powers
assert(math.pow(2, 10) == 1024, "pow")
assert(math.sqrt(16) > 3.99, "sqrt")
assert(math.sqrt(16) < 4.01, "sqrt2")

# Trig
assert(math.sin(0) == 0, "sin(0)")
assert(math.cos(0) == 1, "cos(0)")
assert(math.sin(math.PI / 2) > 0.99, "sin(pi/2)")
assert(math.degrees(math.PI) > 179.9, "degrees")
assert(math.radians(180) > 3.14, "radians")

# Log/exp
assert(math.log(math.E) > 0.99, "log(e)")
assert(math.log2(8) > 2.99, "log2(8)")
assert(math.log10(100) > 1.99, "log10(100)")
assert(math.exp(0) == 1, "exp(0)")

# Hypot/cbrt
assert(math.hypot(3, 4) > 4.99, "hypot")
assert(math.cbrt(27) > 2.99, "cbrt")

# Combinatorics
assert(math.factorial(5) == 120, "factorial")
assert(math.factorial(0) == 1, "factorial(0)")
assert(math.gcd(12, 8) == 4, "gcd")
assert(math.lcm(4, 6) == 12, "lcm")

# Aggregation
assert(math.sum([1, 2, 3, 4]) == 10, "sum")
assert(math.product([1, 2, 3, 4]) == 24, "product")

print("All math tests passed! ✓")
