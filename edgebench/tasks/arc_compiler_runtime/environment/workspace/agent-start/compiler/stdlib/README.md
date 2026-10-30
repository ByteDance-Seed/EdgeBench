# Arc Standard Library

The Arc standard library provides essential modules for common programming tasks, designed with Arc's token-efficiency philosophy.

## Modules

| Module | Status | File | Description |
|--------|--------|------|-------------|
| **math** | ✅ Implemented | [`math.arc`](math.arc) | Constants (PI, E) and functions (abs, pow, sqrt, ceil, floor, clamp) |
| **strings** | ✅ Implemented | [`strings.arc`](strings.arc) | String utilities (pad_left, pad_right, capitalize, words) |
| **collections** | ✅ Implemented | [`collections.arc`](collections.arc) | List utilities (set, unique, group_by, chunk, flatten, zip_with, partition, sort_by) |
| **map** | ✅ Implemented | [`map.arc`](map.arc) | Map utilities (merge, map_values, filter_map, from_pairs, pick, omit) |
| **io** | ✅ Implemented | [`io.arc`](io.arc) | File I/O (read_lines, write_lines, exists, append) |
| **http** | ✅ Implemented | [`http.arc`](http.arc) | HTTP client (get, post, put, delete, fetch_all, parse_url) |
| **json** | ✅ Implemented | [`json.arc`](json.arc) | JSON parser/serializer (to_json, from_json, pretty, get_path) |
| **csv** | ✅ Implemented | [`csv.arc`](csv.arc) | CSV parser/serializer (parse_csv, to_csv, parse_csv_headers) |
| **test** | ✅ Implemented | [`test.arc`](test.arc) | Testing framework (describe, it, expect_eq, expect_true, run_tests) |
| **result** | ✅ Implemented | [`result.arc`](result.arc) | Result type (ok, err, is_ok, unwrap, map_result, try_fn) |
| **time** | ✅ Implemented | [`time.arc`](time.arc) | Time utilities (now, format_duration, sleep) |

## Quick Examples

### math

```arc
use math

math.sqrt(144)        # => 12
math.clamp(15, 0, 10) # => 10
math.PI               # => 3.141592653589793
```

### strings

```arc
use strings

strings.pad_left("7", 3, "0")  # => "007"
strings.capitalize("hello")     # => "Hello"
strings.words("one two three")  # => ["one", "two", "three"]
```

## Built-in Functions (No `use` Required)

Many common operations are built into Arc and need no `use` statement:

`print`, `len`, `str`, `int`, `float`, `type`, `split`, `join`, `trim`, `upper`, `lower`, `slice`, `map`, `filter`, `reduce`, `find`, `contains`, `push`, `concat`, `take`, `skip`, `sort`, `reverse`, `keys`, `values`

## Documentation

- **[Standard Library Reference](../docs/stdlib-reference.md)** — Full API reference
- **[Standard Library Tutorial](../docs/stdlib-tutorial.md)** — Hands-on usage guide

## Design Principles

1. **Minimal but complete** — Cover common use cases without bloat
2. **Token-efficient** — Short names, clear APIs
3. **Pipeline-friendly** — Functions work naturally with `|>`
4. **Well-documented** — Every function has examples
5. **Consistent** — Similar operations have similar signatures

## Contributing

Help implement the planned modules! See [CONTRIBUTING.md](../CONTRIBUTING.md).
