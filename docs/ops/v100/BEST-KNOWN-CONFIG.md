# Best-known V100 32 GB configuration

## Winning build
The best practical point found in the July 2026 campaign was:
- fork: [`TheTom/llama-cpp-turboquant`](https://github.com/TheTom/llama-cpp-turboquant)
- CUDA container/toolchain: **`12.6.3`**
- GPU target: **SM70 / Tesla V100**
- workload class: `Qwen3.6-35B-A3B-Q4_K_M` with VLM enabled

## Why this build won
This build was the best practical compromise because:
- `q8_0 / q8_0` matched `f16 / f16` on perplexity closely enough to be effectively tied on quality
- throughput remained strong
- the 256k VLM serving shape already fit comfortably in 32 GB VRAM
- newer CUDA variants tested here did not improve either throughput or VRAM usage

## Recommended server settings
For the tested workload, the best-known runtime shape is:

```bash
llama-server \
  --model /models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
  --mmproj /models/mmproj-F16.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --ctx-size 262144 \
  --parallel 2 \
  --n-gpu-layers 999 \
  --threads 10 \
  --batch-size 4096 \
  --ubatch-size 1024 \
  --split-mode layer \
  --flash-attn on \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --mmap \
  --jinja \
  --mmproj-offload \
  --image-min-tokens 1024 \
  --metrics --slots
```

## Best-known behavior summary
- Context: `256k`
- Parallel slots: `2`
- KV cache: `q8_0 / q8_0`
- Approximate VRAM usage in the tested VLM shape: **25748 MiB used / 6747 MiB free**
- Decode stayed around **~99 tok/s** in the benchmark pack

## Notes on alternatives
### `f16 / f16`
- slightly better decode
- effectively same PPL as `q8_0 / q8_0`
- higher VRAM footprint
- not the practical winner for this setup

### `q8_0 / turbo2`
- strongest prefill at `PP 2048`
- clear PPL penalty
- only worth it if you explicitly accept the quality trade-off

### `q8_0 / turbo4` and `turbo4 / turbo2`
- saved some VRAM
- did not produce the best speed/quality frontier for this case

## Repo choice
For this exact profile, runtime differences between:
- upstream [`ggml-org/llama.cpp`](https://github.com/ggml-org/llama.cpp)
- and [`TheTom/llama-cpp-turboquant`](https://github.com/TheTom/llama-cpp-turboquant)

were small.

That means:
- upstream is a valid base
- keeping TheTom still makes sense as a lab/hedge for future larger models or memory-constrained cases
