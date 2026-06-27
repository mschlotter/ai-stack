#!/usr/bin/env bash
# Stop AI Agent stack: vLLM + FastCRW incl. SearXNG
# Usage: ai_stop.sh

# Enable Bash strict mode
set -euo pipefail

# Dynamically resolve the absolute path of this script's directory
PROJECT_ROOT="$(dirname "$(readlink -f "$0")")" 

# Check if vLLM is running
function is_vllm_running {
  docker ps --filter "name=vllm" --format "{{.Names}}" | grep -q vllm 2>/dev/null
  return $?
}

echo "=== Stopping AI Agent Stack ==="

# Stop FastCRW
echo "Stopping FastCRW..."
compose_files=("-f" "$PROJECT_ROOT/fastcrw/docker-compose.yml")
if ! is_vllm_running; then
  compose_files+=("-f" "$PROJECT_ROOT/fastcrw/docker-compose.novllm.yml")
fi
docker compose "${compose_files[@]}" down

# Stop vLLM if it was running
if is_vllm_running; then
  echo "Stopping vLLM..."
  docker compose -f "$PROJECT_ROOT/vllm/docker-compose.yml" down
fi

# Remove ai-network if it exists
if docker network inspect ai-network >/dev/null 2>&1; then
  echo "Removing ai-network..."
  docker network rm ai-network
fi

echo ""
echo "=== AI Stack has stopped cleanly ==="
echo "GPU VRAM released."
echo "Model cache preserved at ~/.cache/huggingface"
echo ""
