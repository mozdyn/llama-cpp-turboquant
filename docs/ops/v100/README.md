# V100 32 GB + llama.cpp / TurboQuant

This directory contains a GitHub-ready, sanitized documentation and runtime bundle for running `Qwen3.6-35B-A3B`-class workloads on a `Tesla V100 32 GB` with `llama.cpp` and the TurboQuant fork.

It intentionally excludes:
- private hostnames
- private IP addresses
- usernames
- local absolute paths
- credentials or secrets

## What is included
- [`BEST-KNOWN-CONFIG.md`](./BEST-KNOWN-CONFIG.md) — short description of the winning build and serving parameters
- [`BUILDING.md`](./BUILDING.md) — how to build your own optimized V100 binaries
- [`REPORT.md`](./REPORT.md) — full July 2026 test report
- [`docker-compose.example.yml`](./docker-compose.example.yml) — example `llama-server` deployment using mounted models
- [`entrypoint.sh`](./entrypoint.sh) — runtime helper for the container image
- [`.devops/v100-thetom-cuda126.Dockerfile`](../../../.devops/v100-thetom-cuda126.Dockerfile) — production-style container image for the best-known V100 runtime (no model included)

## Executive summary
For the tested workload:
- model family: `Qwen3.6-35B-A3B`
- quant: `Q4_K_M`
- VLM enabled
- context: `256k`
- single `Tesla V100 32 GB`

The best practical point found was:
- **CUDA 12.6.3**
- **`q8_0 / q8_0` KV cache**
- either upstream `llama.cpp` or `TheTom/llama-cpp-turboquant`, because the measured runtime gap was small

### Main findings
- TheTom TurboQuant fork did **not** show a large runtime-only advantage over upstream for this exact `35B + q8_0/q8_0 + single V100` case.
- Upstream `--prefetch-weights` ([PR #21067](https://github.com/ggml-org/llama.cpp/pull/21067)) worked, but only gave a small point improvement and did not materially change the result.
- CUDA 13 was **not usable** for native V100 builds in the tested container toolchain because `nvcc` rejected `compute_70`.
- CUDA 12.8 built and ran, but was **slower than CUDA 12.6** and showed **no VRAM improvement**.

## Credits
- upstream project: [`ggml-org/llama.cpp`](https://github.com/ggml-org/llama.cpp)
- TurboQuant fork by TheTom: [`TheTom/llama-cpp-turboquant`](https://github.com/TheTom/llama-cpp-turboquant)

## Recommended reading order
1. [`BEST-KNOWN-CONFIG.md`](./BEST-KNOWN-CONFIG.md)
2. [`BUILDING.md`](./BUILDING.md)
3. [`REPORT.md`](./REPORT.md)

## Scope note
This package is focused on the tested `V100 32 GB` single-GPU path. It does **not** claim that the same ranking will hold for:
- larger models
- multi-GPU layouts
- tighter memory budgets
- different CUDA toolchains
- different host PCIe / storage / NUMA topologies
