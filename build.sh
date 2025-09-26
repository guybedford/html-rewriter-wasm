#!/usr/bin/env bash
set -e

echo "---> Checking prerequisites..."
WASM_BINDGEN_VERSION=$(wasm-bindgen --version)
if [[ ! $WASM_BINDGEN_VERSION =~ wasm-bindgen ]]; then
  echo "wasm-bindgen not installed, please install via:"
  echo "cargo install wasm-bindgen-cli"
  exit 1
fi

WASM_OPT_VERSION=$(wasm-opt --version)
if [[ ! $WASM_OPT_VERSION =~ wasm-opt ]]; then
  echo "wasm-opt not installed, please install from Binaryen:"
  echo "https://github.com/WebAssembly/binaryen"
  exit 1
fi

echo "---> Building WebAssembly with wasm-bindgen..."
cargo build --target wasm32v1-unknown-unknown --release
wasm-bindgen target/wasm32-unknown-unknown/release/html_rewriter.wasm --target nodejs --out-dir dist
wasm-opt dist/html_rewriter_bg.wasm -o dist/html_rewriter_bg.wasm --asyncify -Os

echo "---> Patching JavaScript glue code..."
# Wraps write/end with asyncify magic and adds this returns for chaining
# diff -uN pkg/html_rewriter.js pkg2/html_rewriter.js > html_rewriter.js.patch
patch -uN pkg/html_rewriter.js < html_rewriter.js.patch

echo "---> Copying required files to dist..."
mkdir -p dist
cp pkg/html_rewriter.js dist/html_rewriter.js
cp pkg/html_rewriter_bg.wasm dist/html_rewriter_bg.wasm
cp src/asyncify.js dist/asyncify.js
cp src/html_rewriter.d.ts dist/html_rewriter.d.ts
