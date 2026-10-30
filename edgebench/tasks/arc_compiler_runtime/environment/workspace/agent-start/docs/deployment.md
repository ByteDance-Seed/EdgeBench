# Arc Deployment Guide

## Getting Started

### Prerequisites
- **Node.js** 18+ (LTS recommended)
- **npm** 9+

### Quick Install

```bash
# Source repository URL withheld in benchmark package
cd arc-lang/compiler
npm install
```

### Run Arc Programs

```bash
# Run a file
npx tsx src/index.ts run examples/hello-world.arc

# Start the REPL
npx tsx src/index.ts repl

# Check version
npx tsx src/index.ts version
```

---

## npm Package Setup

### Install Globally (after publishing)

```bash
npm install -g arc-lang
arc run myfile.arc
arc version
```

### Build from Source

```bash
cd compiler
npm run build          # Compiles TypeScript → dist/
node dist/index.js run examples/hello-world.arc
```

### Package Structure

The `compiler/package.json` includes:

```json
{
  "name": "arc-lang",
  "version": "0.6.12",
  "bin": { "arc": "./dist/index.js" },
  "scripts": {
    "build": "tsc",
    "prepublishOnly": "tsc"
  }
}
```

### Publish to npm

```bash
cd compiler
npm login
npm publish
```

---

## Docker

### Build the Image

From the repo root:

```bash
docker build -t arc-lang .
```

### Run Arc in Docker

```bash
# Run a file
docker run --rm -v $(pwd)/examples:/app/examples arc-lang run examples/hello-world.arc

# Interactive REPL
docker run --rm -it arc-lang repl

# Check version
docker run --rm arc-lang version
```

---

## CI/CD

The project includes a GitHub Actions workflow at `.github/workflows/ci.yml`:

- **On push/PR to `main`:** runs tests, linter, and benchmarks
- **On version tag (`v*`):** publishes to npm

### Triggering a Release

```bash
git tag v0.5.0
git push origin v0.5.0
```

This triggers the publish job which builds and publishes to npm.

---

## Environment Configuration

### Development

```bash
cd compiler
npm install
npx tsx src/index.ts run <file>   # Direct execution (no build step)
```

- Uses `tsx` for on-the-fly TypeScript execution
- Hot reload: just edit and re-run
- Full source maps and error traces

### Production

```bash
cd compiler
npm run build                      # Compile to JS
node dist/index.js run <file>      # Run compiled version
```

- Pre-compiled JavaScript for faster startup
- No dev dependencies needed at runtime
- Suitable for Docker / serverless deployment

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ARC_DEBUG` | `false` | Enable verbose debug output |
| `ARC_NO_COLOR` | `false` | Disable colored output |
| `ARC_MAX_RECURSION` | `1000` | Maximum recursion depth |
| `NODE_ENV` | `development` | `production` disables debug features |

---

## Recommended Production Setup

1. **Use Docker** for isolation and reproducibility
2. **Pin Node.js version** (18 LTS or 20 LTS)
3. **Run compiled JS** (`npm run build` then `node dist/index.js`)
4. **Set `NODE_ENV=production`** to disable dev features
5. **Use CI/CD** to run tests before every deploy
