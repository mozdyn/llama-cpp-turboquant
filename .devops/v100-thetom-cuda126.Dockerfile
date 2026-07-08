# syntax=docker/dockerfile:1

FROM nvidia/cuda:12.6.3-devel-ubuntu24.04 AS build

ARG REPO_URL=https://github.com/TheTom/llama-cpp-turboquant.git
ARG REPO_REF=main

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    ninja-build \
    python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" repo
WORKDIR /src/repo

RUN cmake -S . -B build-sm70 -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_CUDA=ON \
    -DCMAKE_CUDA_ARCHITECTURES=70 \
    -DGGML_CUDA_F16=ON \
    -DGGML_CUDA_FA=ON \
    -DGGML_CUDA_FORCE_CUBLAS=ON \
    -DGGML_CUDA_FORCE_MMQ=OFF \
    -DGGML_CUDA_GRAPHS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
 && cmake --build build-sm70 -j "$(nproc)"

FROM nvidia/cuda:12.6.3-devel-ubuntu24.04 AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/tq
COPY --from=build /src/repo/build-sm70/bin /opt/tq/bin
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--host", "0.0.0.0", "--port", "8080"]
