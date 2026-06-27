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
  -nv, --novllm    Skip starting vLLM service
  -nc, --nocrw     Skip starting FastCRW service
  -ph, --heavy     Activate FastCRW heavy profile (Chrome for browsing)
  -ps, --stealth   Activate FastCRW heavy profile (Broserless Chrome)
  -h, --help       Show this help message and exit

Endpoints:
  vLLM             → http://localhost:11436/v1
  FastCRW          → http://localhost:11235
EOF
  exit 0
}

echo "=== Starting AI Agent Stack ==="

# Start AI network
function start_network {
  echo "Creating ai-network..."
  if docker network inspect ai-network >/dev/null 2>&1; then
    echo "⚠️ ai-network already exists!"
  else
    docker network create -d bridge ai-network
    echo "✅ ai-network created!"
  fi
  echo ""
}

# Start vLLM service
function start_vllm {
  echo "Starting vLLM (this may take a few minutes)..."
  docker compose -f "$PROJECT_ROOT/vllm/docker-compose.yml" up -d

  for i in $(seq 1 120); do
    if curl -s http://localhost:11436/v1/models >/dev/null 2>&1; then
      echo "✅ vLLM is ready!"
      echo ""
      return 0
    fi
    if [ "$i" -eq 120 ]; then
      echo "❌ vLLM timed out — check logs: docker compose logs vllm"
      echo ""
      return 1
    fi
    sleep 3
  done
}

# Start FastCRW service
function start_crw {
  echo "Starting FastCRW..."
  local compose_cmd=("-f" "$PROJECT_ROOT/fastcrw/docker-compose.yml")
  if ! $START_VLLM; then
    compose_cmd+=("-f" "$PROJECT_ROOT/fastcrw/docker-compose.novllm.yml")
  fi
  if $PROFILE_HEAVY; then
    compose_cmd+=("--profile" "heavy")
  fi
  if $PROFILE_STEALTH; then
    compose_cmd+=("--profile" "stealth")
  fi
  docker compose "${compose_cmd[@]}" up -d
  echo "✅ FastCRW is ready!"
}

# Initialize arguments
START_VLLM=true
START_CRW=true
PROFILE_HEAVY=false
PROFILE_STEALTH=false

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
    -ph|--heavy)
      PROFILE_HEAVY=true
      shift
      ;;
    -ps|--stealth)
      PROFILE_STEALTH=true
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
start_network

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

# Print endpoints for started services
if $START_VLLM; then
  echo "vLLM     ➔ http://localhost:11436/v1"
fi
if $START_CRW; then
  echo "FastCRW  ➔ http://localhost:11235"
fi
echo ""
