# Mozdyn V100 fork workflow

## Repo roles
- `origin` -> `https://github.com/mozdyn/llama-cpp-turboquant`
- `upstream` -> `https://github.com/TheTom/llama-cpp-turboquant`
- local path -> `/home/openclaw/workspace/projects/llama-cpp-v100`

## Branch model
- upstream default branch: `feature/turboquant-kv-cache`
- local tracking branch: `feature/turboquant-kv-cache`
- local customization branch: `v100`

## Why fork first
- keeps upstream history intact
- allows regular sync from TheTom
- isolates V100-specific patches
- gives clean place to document decisions and benchmarks

## Sync routine
```bash
git fetch upstream --prune
git checkout feature/turboquant-kv-cache
git merge --ff-only upstream/feature/turboquant-kv-cache || git merge upstream/feature/turboquant-kv-cache
git push origin feature/turboquant-kv-cache

git checkout v100
git rebase feature/turboquant-kv-cache || git merge feature/turboquant-kv-cache
git push --force-with-lease origin v100
```

## Safety rule
- never mix upstream sync and custom V100 optimization in one commit
- keep perf tuning, compatibility fixes, and docs in separate commits
- if `v100` becomes shared, prefer merge over rebase

## Initial state created by Marian
- GitHub auth configured locally via `gh`
- fork created under `mozdyn/llama-cpp-turboquant`
- `upstream` remote added
- local `v100` branch created from upstream default branch

## Next technical step
1. inspect current CUDA/V100 support in this fork
2. identify build flags and kernels that are weak or disabled on V100
3. define first patch set: build, runtime, kernels, benchmarks
