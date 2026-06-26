#!/usr/bin/env bash
# Start AI Agent stack: vLLM + FastCRW incl. SearXNG

# Enable Bash strict mode
set -euo pipefail

# Dynamically resolve the absolute path of this script's directory
PROJECT_ROOT="$(dirname "$(readlink -f "$0")")"

echo "=== Stopping AI Agent Stack ==="

# Stop and clean up containers
echo "Stopping FastCRW..."
docker compose -f "$PROJECT_ROOT/fastcrw/docker-compose.yml" down

echo "Stopping vLLM..."
docker compose -f "$PROJECT_ROOT/vllm/docker-compose.yml" down

echo ""
echo "=== AI Stack has stopped cleanly ==="
echo "  → GPU VRAM released."
echo "  → Model cache preserved at ~/.cache/huggingface"
echo ""
