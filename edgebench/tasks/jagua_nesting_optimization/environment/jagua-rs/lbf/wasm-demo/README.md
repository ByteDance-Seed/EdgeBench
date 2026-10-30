# WASM Demo for `jagua-rs`

Visit [https://jeroengar.github.io/jagua-rs/lbf-wasm-demo/](https://jeroengar.github.io/jagua-rs/lbf-wasm-demo/)

### Build and serve locally

From the root of the repository:

```bash
cargo install wasm-pack
cd lbf
wasm-pack build --target web --release --out-dir wasm-demo/pkg
python serve.py
```

Or check [wasm.yml](../../.github/workflows/wasm.yml) for the CI workflow that builds and deploys this demo.