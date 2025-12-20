# Cairo WASM Integration

This directory contains the Cairo-VM WASM bindings for the caps-jam project.

## Structure

- `cairo/` - Cairo source code
- `src/` - Rust WASM bindings
- `pkg/` - Generated WASM package (after build)

## Building

### Quick Build (recommended)

```bash
cd wasm
./build.sh
```

This script will:
1. Activate the cairo-vm environment
2. Compile Cairo to Sierra using Cairo 2 compiler
3. Build the WASM package with `wasm-pack`

### Manual Build Steps

If you prefer to build manually:

```bash
# 1. Activate cairo-vm environment
source ~/cairo-vm/cairo-vm-env/bin/activate

# 2. Compile Cairo to Sierra (using Cairo 2)
~/cairo-vm/cairo2/bin/cairo-compile --single-file -r cairo/types.cairo cairo/types.sierra

# 3. Build WASM package
wasm-pack build --target=web
```

This generates the `pkg/` directory with the WebAssembly module and JavaScript bindings.

## Usage in Client

### Import and Use

```typescript
import init, { runCairoProgram } from '$lib/../../wasm/pkg/caps_wasm';
import { parseCapType } from '$lib';

// Initialize WASM module
await init();

// Run Cairo program with cap type ID
const rawOutput = await runCairoProgram(4);

// Parse the output
const capType = parseCapType(rawOutput);
console.log(capType);
// {
//   id: 4,
//   name: "Red Basic",
//   description: "Cap 3",
//   move_cost: 1,
//   ...
// }
```

## Adding More Cap Types

Edit `cairo/types.cairo` and add more match arms to the `main` function, then rebuild.

