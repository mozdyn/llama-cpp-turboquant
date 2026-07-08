# V100 llama.cpp / TurboQuant test report

Date range: 2026-07-07 → 2026-07-08

## 1. Goal
The goal of this campaign was to identify the most practical runtime shape for `Qwen3.6-35B-A3B-UD-Q4_K_M` on a `Nvidia V100 32 GB`, with emphasis on:
- the real value of different KV-cache profiles,
- the effect of the upstream `--prefetch-weights` patch,
- the effect of different CUDA container/toolchain versions,
- and practical VLM fit / throughput behavior at full `ctx=256k`.

## 2. Test environment
### Hardware / platform
- Virtualization: **KVM guest on Proxmox VE**
- Guest OS: **Ubuntu 26.04 LTS**
- Kernel: `Linux 7.0.0-27-generic`
- NVIDIA driver: `580.159.03`
- Benchmark GPU: Nvidia V100 32 GB PCI-E 
- Llama Server settings tuned with llama-optimus for tested setup

### Model / workload
- Base model: `Qwen3.6-35B-A3B-UD-Q4_K_M.gguf`
- VLM projector: `mmproj-F16.gguf`
- Main server shape under test:
  - `ctx=262144`
  - `parallel=2`
  - `batch=4096`
  - `ubatch=1024`
  - `flash-attn=on`
  - `ngl=999`

### Common benchmark settings
- `-ngl 999`
- `-fa on`
- `-sm layer`
- `-mg 0`
- `-b 4096`
- `-ub 1024`
- `-r 3`
- prompts: `512`, `2048`
- generations: `128`, `512`

## 3. What was tested
### 3.1 KV cache profile matrix on TheTom CUDA 12.6
Profiles:
- `f16 / f16`
- `q8_0 / q8_0`
- `q8_0 / turbo4`
- `q8_0 / turbo2`
- `turbo4 / turbo2`

### 3.2 Upstream vs TheTom
- built isolated upstream `ggml-org/llama.cpp`
- benchmarked upstream `q8_0/q8_0`
- compared against the previous TheTom/Hermes build

### 3.3 Upstream prefetch patch
- identified patch: [ggml-org/llama.cpp PR #21067](https://github.com/ggml-org/llama.cpp/pull/21067)
- ported and built an isolated upstream tree exposing:
  - `-pw`
  - `--prefetch-weights`
- benchmarked:
  - `--mmap 0 -pw 0`
  - `--mmap 0 -pw 1`

### 3.4 CUDA toolchain variants
- CUDA 13 rebuild attempt for TheTom
- CUDA 12.8 rebuild for TheTom
- smoke / benchmark / VRAM comparison vs CUDA 12.6

## 4. Core results — KV throughput and PPL
| KV profile | PP 512 | PP 2048 | TG 128 | TG 512 | PPL |
|---|---:|---:|---:|---:|---:|
| `f16 / f16` | 920.5 | 1106.5 | 100.6 | 100.8 | 5.7041 |
| `q8_0 / q8_0` | 923.7 | 1098.4 | 99.3 | 99.3 | 5.7043 |
| `q8_0 / turbo4` | 873.5 | 1106.6 | 97.4 | 96.5 | 5.7139 |
| `q8_0 / turbo2` | 924.1 | 1125.1 | 98.2 | 98.0 | 5.7643 |
| `turbo4 / turbo2` | 916.4 | 1097.5 | 97.5 | 97.4 | 5.7724 |

## 5. Interpretation of KV results
### `f16 / f16`
- best decode
- nearly identical quality to `q8_0/q8_0`
- but not the best practical overall point for this use case

### `q8_0 / q8_0`
- best quality/performance compromise
- PPL is effectively tied with `f16/f16`
- throughput is strong enough that this became the practical winner

### `q8_0 / turbo2`
- best prefill at `2048`
- but with a clear quality cost
- only worth it if that trade-off is explicitly desired

### `q8_0 / turbo4` and `turbo4 / turbo2`
- did not provide any significant value

## 6. VLM VRAM fit at `ctx=256k`
| KV profile | Fit | VRAM used MiB | VRAM free MiB |
|---|---|---:|---:|
| `f16 / f16` | yes | 27684 | 4811 |
| `q8_0 / q8_0` | yes | 25748 | 6747 |
| `q8_0 / turbo4` | yes | 25048 | 7447 |
| `q8_0 / turbo2` | yes | 24830 | 7665 |
| `turbo4 / turbo2` | yes | 24148 | 8347 |

### Read
- all tested variants fit
- TurboQuant did save VRAM, but in this lane the savings were no longer necessary because `q8_0/q8_0` already fit comfortably

## 7. Upstream vs TheTom
Benchmarked `q8_0/q8_0`:

| Metric | Previous build | Upstream build | Delta | Delta % |
|---|---:|---:|---:|---:|
| PP 512 | 923.7 | 901.9 | -21.7 | -2.35% |
| PP 2048 | 1098.4 | 1097.0 | -1.4 | -0.13% |
| TG 128 | 99.3 | 99.1 | -0.3 | -0.25% |
| TG 512 | 99.3 | 98.9 | -0.3 | -0.34% |

### Verdict
- the differences are small
- upstream is a fully viable base for this profile
- TheTom does not buy a large runtime-only advantage here

## 8. Upstream `--prefetch-weights` (`PR #21067`)
### Results
| Metric | Prev build | Upstream mmap | PW build no-mmap pw=0 | PW build no-mmap pw=1 |
|---|---:|---:|---:|---:|
| PP 512 | 923.67 | 901.95 | 900.66 | 900.13 |
| PP 2048 | 1098.41 | 1096.99 | 1094.69 | 1109.79 |
| TG 128 | 99.35 | 99.09 | 98.78 | 98.67 |
| TG 512 | 99.27 | 98.93 | 98.94 | 98.18 |

### Read
- the patch is real and functional
- `pw=1` gave a small gain at `PP 2048`
- it did not improve `PP 512`
- it slightly hurt decode
- final verdict: **not high-ROI for this workload**

## 9. CUDA 13
- CUDA 13 toolchain does not support for V100 / SM70 architecture

## 10. CUDA 12.8
### Build status
- image pulled: `nvidia/cuda:12.8.1-devel-ubuntu24.04`
- TheTom build succeeded
- smoke succeeded

### Throughput vs 12.6
| Metric | CUDA 12.6 | CUDA 12.8 | Delta | Delta % |
|---|---:|---:|---:|---:|
| PP 512 | 923.674880 | 916.763731 | -6.911149 | -0.75% |
| PP 2048 | 1098.410587 | 1084.566035 | -13.844552 | -1.26% |
| TG 128 | 99.346992 | 98.525128 | -0.821864 | -0.83% |
| TG 512 | 99.270482 | 98.449731 | -0.820751 | -0.83% |

### VRAM vs 12.6
| Runtime | GPU1 used | GPU1 free |
|---|---:|---:|
| TheTom CUDA 12.6 | 25748 MiB | 6747 MiB |
| TheTom CUDA 12.8 | 25748 MiB | 6747 MiB |

### Verdict
- CUDA 12.8 is **strictly worse** for this case:
  - same VRAM
  - lower throughput

## 11. Historical context: old `llm-core` 2x RTX 5060 Ti
Older findings from:
- `docs/architecture/2026-04-27-llm-core-qwen36-universal-findings.md`

showed that:
- `llm-core` had `2x RTX 5060 Ti 16 GB`
- `35B-A3B universal + embeddings` was stably validated at about `200k ctx`
- `27B + TurboQuant + 256k ctx` worked technically
- `27B + TurboQuant + vision + embeddings + 256k ctx` was a strong candidate on that hardware

### Important caution
This is **not an apples-to-apples throughput comparison**, because:
- different host
- different GPU layout
- different project phase
- no equivalent PP/TG/PPL pack in that older note

Still, the architectural lesson is useful:
- TurboQuant was more helpful under a tighter or more distributed memory budget than in the current 35B-on-single-V100 case

## 12. Final practical conclusion
For:
- `Qwen3.6-35B-A3B-Q4_K_M`
- one `Tesla V100 32 GB`
- VLM `ctx=256k`
- quality-first usage with decode around `~100 tok/s`

The best practical point found in this campaign remains:
- **CUDA 12.6**
- **`q8_0 / q8_0`**
- either TheTom or upstream depending on repo/workflow preference, because the runtime gap is small

### Repo recommendation
- **TheTom** still makes sense as a lab / working fork / hedge for future models >35B
- **upstream** is close enough to act as a realistic baseline and viable base
- further optimization of fork-choice alone does not currently look like the highest-ROI path

## 13. Related docs
- [README.md](./README.md)
- [BEST-KNOWN-CONFIG.md](./BEST-KNOWN-CONFIG.md)
- [BUILDING.md](./BUILDING.md)

## 14. Credits
- upstream project: [`ggml-org/llama.cpp`](https://github.com/ggml-org/llama.cpp)
- TurboQuant fork by TheTom: [`TheTom/llama-cpp-turboquant`](https://github.com/TheTom/llama-cpp-turboquant)
