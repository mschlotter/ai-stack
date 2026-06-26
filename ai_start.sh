#!/usr/bin/env bash
# Start AI Agent stack: vLLM + FastCRW incl. SearXNG
# Usage: ai_start.sh [--novllm] [--nocrw]

set -euo pipefail

# Global parameters
PROJECT_ROOT="$(dirname "$(readlink -f "$0")")"

# Help function
function show_help {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Start AI Agent stack: vLLM + FastCRW incl. SearXNG

Options:
  -nv, --novllm  Skip starting vLLM service
  -nc, --nocrw   Skip starting FastCRW service
  -h, --help     Show this help message and exit

Endpoints:
  vLLM           → http://localhost:11436/v1
  FastCRW        → http://localhost:11235
EOF
  exit 0
}

echo "=== Starting AI Agent Stack ==="

# Start vLLM service
function start_vllm {
  echo "Starting vLLM..."
  docker compose -f "$PROJECT_ROOT/vllm/docker-compose.yml" up -d

  echo "Waiting for vLLM to finish loading the model..."
  for i in $(seq 1 120); do
    if curl -s http://localhost:11436/v1/models >/dev/null 2>&1; then
      echo "  ✓ vLLM is ready!"
      return 0
    fi
    if [ "$i" -eq 120 ]; then
      echo "  ✗ vLLM timed out — check logs: docker compose logs vllm"
      return 1
    fi
    sleep 3
  done
}

# Start FastCRW service
function start_crw {
  echo "Starting FastCRW..."
  docker compose -f "$PROJECT_ROOT/fastcrw/docker-compose.yml" up -d
  echo "  ✓ FastCRW is ready!"
}

# Initialize arguments
START_VLLM=true
START_CRW=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      ;;
    -nv|--novllm)
      START_VLLM=false
      shift
      ;;
    -nc|--nocrw)
      START_CRW=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Try '$(basename "$0") --help' for more information."
      exit 1
      ;;
  esac
done

# Execute start functions based on flags
if $START_VLLM; then
  start_vllm || exit 1
else
  echo "Skipping vLLM (--novllm)"
fi

if $START_CRW; then
  start_crw
else
  echo "Skipping FastCRW (--nocrw)"
fi

echo ""
echo "=== Stack is running ==="
echo ""

# Print endpoints for started services
if $START_VLLM; then
  echo "  vLLM         → http://localhost:11436/v1"
fi
if $START_CRW; then
  echo "  FastCRW      → http://localhost:11235"
fi
echo ""
