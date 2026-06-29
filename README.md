# AI Stack

A fully local, Docker-based AI stack providing an OpenAI-compatible API and a web-search-capable MCP server — no API keys required.

Powered by [vLLM](https://github.com/vllm-project/vllm) for serving the local LLM and [FastCRW](https://github.com/us/crw) for scraping, crawling, and search via a bundled SearXNG sidecar.

---

## Features

- **Fully Local** — No external API calls or API keys needed. Everything runs on your machine via Docker.
- **OpenAI-Compatible API** — vLLM exposes a `/v1` endpoint that works with any OpenAI SDK-compatible client at `http://localhost:11436/v1`.
- **Built-in Web Search** — SearXNG sidecar provides a `/v1/search` endpoint for real-time search from agents.
- **Web Scraping & Crawling** — FastCRW handles page rendering, document parsing (PDF), and URL mapping.
- **Multiple Browser Profiles** — Choose from vanilla headless Chrome, full Chrome, or Browserless stealth Chrome via `--profile`.
- **Model Caching** — Hugging Face models are cached in `~/.cache/huggingface` across runs.
- **Memory-Safe Containers** — All services run with `read_only: true`, dropped capabilities, and resource limits.
- **Modular Services** — Start vLLM, FastCRW, or both independently with CLI flags.

---

## Quick Start

### Prerequisites

- Docker & Docker Compose v2
- NVIDIA GPU with CUDA support (optional, for LLM inference)

### Start the Stack

```bash
# Start everything (vLLM + FastCRW)
./ai_start.sh

# Start only FastCRW (skip the local LLM)
./ai_start.sh --novllm

# Start only vLLM (skip FastCRW)
./ai_start.sh --nocrw
```

vLLM downloads and loads the model on first start (~2–5 min). Subsequent starts are near-instant.

### Verify It Works

```bash
# Check vLLM (OpenAI-compatible API)
curl http://localhost:11436/v1/models

# Check FastCRW health
curl http://localhost:11235/health

# Test a completion request
curl http://localhost:11436/v1/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"nvidia/Qwen3.6-35B-A3B-NVFP4","prompt":"Hello!","max_tokens":64}'
```

### Stop the Stack

```bash
./ai_stop.sh
```

---

## Configuration

### Environment Variables

Copy and edit the example files before first use:

**`fastcrw/.env`**

```env
# LLM connection (points to local vLLM by default)
LLM_PROVIDER=openai-compatible
LLM_BASE_URL=http://vllm:8000/v1
LLM_MODEL=nvidia/Qwen3.6-35B-A3B-NVFP4
LLM_API_KEY=vllm

# SearXNG secret key (change from default)
SEARXNG_SECRET_KEY=<openssl-rand-hex-32>

# Browserless token (change from default)
BROWSERLESS_TOKEN=<openssl-rand-hex-24>
```

**`vllm/.env`**

```env
# Hugging Face token (required for model downloads)
HF_TOKEN=hf_...
```

### Configuration Files

| File | Purpose |
|------|---------|
| `fastcrw/config.docker.toml` | FastCRW runtime settings — render timeouts, crawler limits, search config, PDF parsing |
| `fastcrw/config/searxng/settings.yml` | SearXNG search engine settings (engines, UI, preferences) |

### Service Endpoints

| Service | URL | Description |
|---------|-----|-------------|
| vLLM | `http://localhost:11436/v1` | OpenAI-compatible LLM API |
| FastCRW | `http://localhost:11235` | Scraping / crawling API |
| SearXNG | `http://localhost:8080` | Search engine (admin UI) |
| LightPanda | `ws://lightpanda:9222` | Lightweight JS renderer (internal) |
| Chrome | `ws://chrome:9222` | Headless Chrome renderer (internal) |

---

## Project Structure

```
ai/
├── ai_start.sh              # Start script (vLLM + FastCRW)
├── ai_stop.sh               # Stop script (clean shutdown)
├── .gitignore
├── fastcrw/                 # FastCRW web scraping & search service
│   ├── docker-compose.yml       # Main stack (CRW + SearXNG + renderers)
│   ├── docker-compose.stealth.yml  # Browserless stealth Chrome profile
│   ├── docker-compose.novllm.yml # Fallback config when vLLM is absent
│   ├── config.docker.toml       # FastCRW runtime configuration
│   ├── .env                           # Environment variables
│   ├── .env.example                   # Template with defaults
│   └── config/searxng/settings.yml    # SearXNG engine settings
└── vllm/                    # vLLM local LLM inference service
    ├── docker-compose.yml       # GPU-accelerated vLLM container
    ├── .env                       # Hugging Face token
    └── .env.example               # Template
```

### Service Architecture

```
┌─────────────────────────────────────────────────────┐
│  Docker bridge                                      │
│                                                     │
│  ┌──────────┐    ┌──────────────┐    ┌───────────┐  │
│  │  vLLM    │───>│  CRW Service │    │ SearXNG   │  │
│  │ :8000    │    │  :3000       │<───│  :8080    │  │
│  └──────────┘    └──────┬───────┘    └───────────┘  │
│                         │                           │
│              ┌──────────┴──────────┐                │
│              │   JS Renderers      │                │
│              │  LightPanda | Chrome│                │
│              └─────────────────────┘                │
└─────────────────────────────────────────────────────┘
     │                        │
     ▼                        ▼
localhost:11436/v1     localhost:11235
(OpenAI API)           (Scraping API)
```

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Container Runtime** | Docker / Docker Compose |
| **LLM Inference** | vLLM (`vllm/vllm-openai`) with ModelOpt quantization |
| **LLM Model** | Qwen3.6-35B-A3B-NVFP4 (4-bit NVFP4 quantized) |
| **Web Search** | SearXNG (self-hosted metasearch engine) |
| **Web Scraping** | FastCRW (Rust-based, multi-engine crawler) |
| **JS Rendering** | LightPanda (primary) + Chrome / Chrome-Stealth (fallback) |
| **PDF Parsing** | Sandboxed document parser (built into FastCRW) |
| **GPU Acceleration** | NVIDIA Container Toolkit |
| **Model Hub** | Hugging Face (cached to `~/.cache/huggingface`) |

---

## Scripts

| Command | Description |
|---------|-------------|
| `./ai_start.sh` | Start the full stack (vLLM + FastCRW) |
| `./ai_start.sh --novllm` | Start only FastCRW (no LLM, uses external API) |
| `./ai_start.sh --nocrw` | Start only vLLM (no FastCRW) |
| `./ai_start.sh --heavy` | Enable full Chrome browser (not headless-shell) |
| `./ai_start.sh --stealth` | Enable Browserless stealth Chrome profile |
| `./ai_stop.sh` | Stop all services and clean up the network |
| `./ai_start.sh --help` | Show usage and endpoint info |

### Short Options

| Flag | Long Form | Description |
|------|-----------|-------------|
| `-nv` | `--novllm` | Skip vLLM service |
| `-nc` | `--nocrw` | Skip FastCRW service |
| `-ph` | `--heavy` | Use full Chrome instead of headless-shell |
| `-ps` | `--stealth` | Use Browserless stealth Chrome |
| `-h` | `--help` | Show help message |


## License

This project is licensed under the MIT License.
