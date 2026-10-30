# Hello World Examples

This directory contains simple "Hello World" programs demonstrating Arc's efficiency gains compared to JavaScript and Python.

## Quick Comparison

| Language | Tokens | Code Size | Efficiency Gain |
|----------|--------|-----------|-----------------|
| Arc | 5 | 21 bytes | Baseline |
| Python | 7 | 25 bytes | Arc uses 29% fewer tokens |
| JavaScript | 10 | 30 bytes | Arc uses 50% fewer tokens |

## Files

- `hello.arc` - Arc version
- `hello.js` - JavaScript version
- `hello.py` - Python version
- `comparison.md` - Detailed analysis

## Run Examples

```bash
# Arc
arc run hello.arc

# JavaScript
node hello.js

# Python
python3 hello.py
```

All three produce identical output: `Hello, Arc!`

## Why This Matters

For AI agents generating code:
- **Fewer tokens** = lower API costs
- **Simpler syntax** = faster generation
- **Less boilerplate** = easier to maintain

Even in this trivial example, Arc demonstrates measurable efficiency gains. Real-world programs show 50%+ token reduction.

See [comparison.md](comparison.md) for detailed token-by-token analysis.
