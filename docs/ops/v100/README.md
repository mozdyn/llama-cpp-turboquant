# V100 32 GB + llama.cpp / TurboQuant

This directory contains a GitHub-ready, sanitized documentation and runtime bundle for running `Qwen3.6-35B-A3B`-class workloads on a `Nvidia V100 32 GB` with upstream `llama.cpp` and the TurboQuant fork.

## Executive summary
For the tested workload:
- model family: `Qwen3.6-35B-A3B`
- quant: `Q4_K_M`
- VLM enabled
- context: `256k`
- single `Nvidia V100 32 GB`

The best practical point found was:
- **CUDA 12.6.3**
- **q8_0 / q8_0 KV cache**
- **TheTom/llama-cpp-turboquant**

### Why it matters
Nvidia V100 is still valuable option for local interference when taking into consideration entry price and possibility to comfortably run local 35B MoE LLM's. 
In comparison with dual RTX5060Ti setup, it provides:
- similar decode speed at 90-100 t/s (how fast your LLM writes to you)
- much slower prefill at 1100 t/s (how long will you wait for first token after asking the question - this is crucial as my Hermes agent has  25k of initial prompt, so first token comes after about 25-30s)
- better VRAM fit (as dual GPU has some overhead)
- require some DIY for cooling and it's louder (3d printed air duct, 7$ fan, 3$ fan controller and some skills) 
- PCI-E is ok for single-gpu setups, for multi-gpu chose SMX/NVLink version (more DIY needed). 
- Comfortable VRAM fit for decent 35B MoE up to Q5 with vision and full 256k CTX. 

### Main findings
- TheTom TurboQuant fork did **not** show a large speed/size advantage over upstream for this exact `35B + q8_0/q8_0 + single 32GB V100` case, but gives KV tq compression options for future use.
- Upstream `--prefetch-weights` ([PR #21067](https://github.com/ggml-org/llama.cpp/pull/21067)) worked, but did not significantly improved the result.
- CUDA 13 do not support V100/SM70 builds.
- CUDA 12.8 built and ran, but was **slower than CUDA 12.6** and showed **no VRAM improvement**.

## What is included
- [`BEST-KNOWN-CONFIG.md`](./BEST-KNOWN-CONFIG.md) — short description of the winning build and serving parameters
- [`BUILDING.md`](./BUILDING.md) — how to build your own optimized V100 binaries
- [`REPORT.md`](./REPORT.md) — full July 2026 test report
- [`.devops/v100-thetom-cuda126.Dockerfile`](../../../.devops/v100-thetom-cuda126.Dockerfile) — production-style container image for the best-known V100 runtime
- [`docker-compose.example.yml`](./docker-compose.example.yml) — example `llama-server` deployment using mounted models
- [`entrypoint.sh`](./entrypoint.sh) — runtime helper used by the container

## Credits
- upstream project: [`ggml-org/llama.cpp`](https://github.com/ggml-org/llama.cpp)
- TurboQuant fork by TheTom: [`TheTom/llama-cpp-turboquant`](https://github.com/TheTom/llama-cpp-turboquant)

## Scope note
This package is focused on the tested `V100 32 GB` single-GPU path. It does **not** claim that the same ranking will hold for:
- larger models
- multi-GPU layouts
- tighter memory budgets
- different CUDA toolchains
- different host PCIe / storage / NUMA topologies
