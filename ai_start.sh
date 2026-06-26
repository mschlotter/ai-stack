#!/usr/bin/env bash
# Start AI Agent stack: vLLM + FastCRW incl. SearXNG
# Usage: ai_start.sh [--novllm] [--nocrw]

set -euo pipefail

PROJECT_ROOT="$(dirname "$(readlink -f "$0")")"

START_VLLM=true
START_CRW=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --novllm)
      START_VLLM=false
      shift
      ;;
    --nocrw)
      START_CRW=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "=== Starting AI Agent Stack ==="

# 1. Start vLLM (if not disabled)
if $START_VLLM; then
  echo "Starting vLLM..."
  docker compose -f "$PROJECT_ROOT/vllm/docker-compose.yml" up -d

  echo "Waiting for vLLM to finish loading the model..."
  for i in $(seq 1 120); do
    if curl -s http://localhost:11436/v1/models >/dev/null 2>&1; then
      echo "  ✓ vLLM is ready!"
      break
    fi
    if [ "$i" -eq 120 ]; then
      echo "  ✗ vLLM timed out — check logs: docker compose logs vllm"
      exit 1
    fi
    sleep 3
  done
else
  echo "Skipping vLLM (--novllm)"
fi

# 2. Start FastCRW (if not disabled)
if $START_CRW; then
  echo "Starting FastCRW..."
  docker compose -f "$PROJECT_ROOT/fastcrw/docker-compose.yml" up -d
  echo "  ✓ FastCRW is ready!"
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
echo "  SearXNG      → http://localhost:8888"
echo ""
