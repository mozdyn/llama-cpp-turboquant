# Building optimized V100 binaries

This guide describes how to build your own `Tesla V100 / SM70`-optimized binaries for the TurboQuant fork.

## Upstream / fork reference
- TurboQuant fork: [`TheTom/llama-cpp-turboquant`](https://github.com/TheTom/llama-cpp-turboquant)
- Upstream reference project: [`ggml-org/llama.cpp`](https://github.com/ggml-org/llama.cpp)

## Recommended toolchain
Use:
- **CUDA 12.6.3**
- Ubuntu 24.04 CUDA devel image
- `cmake + ninja`

Do **not** use the tested CUDA 13 image for V100 native builds in this workflow: in our test it rejected `compute_70`.

## Clone
```bash
git clone https://github.com/TheTom/llama-cpp-turboquant.git
cd llama-cpp-turboquant
```

## Build in Docker (recommended)
The simplest reproducible path is to build inside the official CUDA 12.6.3 devel image.

```bash
docker run --rm --gpus all \
  -v "$PWD":/src \
  -w /src \
  nvidia/cuda:12.6.3-devel-ubuntu24.04 \
  bash -lc '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends \
      build-essential git cmake ninja-build python3 ca-certificates

    cmake -S /src -B /src/build-sm70 -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DGGML_CUDA=ON \
      -DCMAKE_CUDA_ARCHITECTURES=70 \
      -DGGML_CUDA_F16=ON \
      -DGGML_CUDA_FA=ON \
      -DGGML_CUDA_FORCE_CUBLAS=ON \
      -DGGML_CUDA_FORCE_MMQ=OFF \
      -DGGML_CUDA_GRAPHS=ON \
      -DLLAMA_BUILD_TESTS=OFF \
      -DLLAMA_BUILD_EXAMPLES=OFF

    cmake --build /src/build-sm70 -j "$(nproc)"
  '
```

## Important build flags
- `-DCMAKE_CUDA_ARCHITECTURES=70`
  - targets V100 / SM70 directly
- `-DGGML_CUDA_FORCE_CUBLAS=ON`
  - this was part of the best-known build shape
- `-DGGML_CUDA_FORCE_MMQ=OFF`
  - kept disabled in the winning configuration
- `-DLLAMA_BUILD_TESTS=OFF`
- `-DLLAMA_BUILD_EXAMPLES=OFF`
  - reduces build surface and avoids unnecessary failures for this deployment-oriented build

## Expected output binaries
After a successful build, you should have at least:
- `llama-server`
- `llama-bench`
- `llama-perplexity`
- `llama-cli`
- `llama-quantize`

inside your build directory, for example:
- `build-sm70/bin/`

## Local runtime note
If your host does not provide matching CUDA user-space libraries, do **not** run the binaries directly on the host and assume a runtime failure means a bad build.

Instead, run them inside a matching CUDA container and mount the build tree into the container.

## Related docs
- [README.md](./README.md)
- [BEST-KNOWN-CONFIG.md](./BEST-KNOWN-CONFIG.md)
- [REPORT.md](./REPORT.md)
