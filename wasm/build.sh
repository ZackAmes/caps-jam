#!/bin/bash
set -e

echo "📦 Building Cairo WASM Integration..."

# Step 0: Source cairo-vm environment
echo "0️⃣  Activating Cairo VM environment..."
cd "$(dirname "$0")"
source ~/cairo-vm/cairo-vm-env/bin/activate

# Step 1: Compile Cairo to Sierra using cairo-compile (Cairo 2)
echo "1️⃣  Compiling Cairo to Sierra..."
~/cairo-vm/cairo2/bin/cairo-compile --single-file -r cairo/types.cairo cairo/types.sierra

# Step 2: Build WASM package
echo "2️⃣  Building WASM package..."
wasm-pack build --target=web

echo "✅ Build complete! WASM package is in pkg/"
echo "📝 You can now use it in your Svelte app"

