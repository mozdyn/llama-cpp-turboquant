#!/usr/bin/env bash
set -euo pipefail

export LD_LIBRARY_PATH="/opt/tq/bin:${LD_LIBRARY_PATH:-}"
exec /opt/tq/bin/llama-server "$@"
