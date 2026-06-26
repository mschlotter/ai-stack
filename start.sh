#!/usr/bin/env bash
# Start AI Agent stack: vLLM + FastCRW incl. SearXNG

# Enable Bash strict mode
set -euo pipefail

# Dynamically resolve the absolute path of this script's directory
PROJECT_ROOT="$(dirname "$(readlink -f "$0")")"

echo "=== Starting AI Agent Stack ==="

# 1. Start vLLM
echo "Starting vLLM..."
docker compose -f "$PROJECT_ROOT/vllm/docker-compose.yml" up -d

# Wait for vLLM to be ready
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

# 2. Start FastCRW
echo "Starting FastCRW..."
docker compose -f "$PROJECT_ROOT/fastcrw/docker-compose.yml" up -d
echo "  ✓ FastCRW is ready!"

echo ""
echo "=== Stack is running ==="
echo ""
echo "  vLLM         → http://localhost:11436/v1"
echo "  FastCRW      → http://localhost:11235"
echo "  SearXNG      → http://localhost:8888"
echo ""
