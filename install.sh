#!/usr/bin/env bash

set -euo pipefail

function _install_mori_llama() {
    clear

    echo -e "\n🔄  Initializing Mori Ollama Setup...\n"

    echo "💻️ Checking Docker & Docker Compose..."
    
    if ! command -v docker &>/dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! docker compose version &>/dev/null; then
        echo "❌ Docker Compose v2 is required. Install or upgrade Docker."
        exit 1
    fi

    if ! docker ps &>/dev/null; then
        echo "❌ Docker is not running. Please start Docker first."
        exit 1
    fi

    echo "🔧 Creating Docker volumes..."
    docker volume create llm-ui-vol &>/dev/null || true
    docker volume create llm-app-vol &>/dev/null || true

    echo "🌐 Creating Docker networks..."
    docker network create hub-ass-priv-net --subnet=10.0.0.0/28 &>/dev/null || true
    docker network create hub-ass-pub-net &>/dev/null || true

    echo "🚀 Starting containers with Docker Compose..."
    docker compose up -d --build --force-recreate

    echo "✅ Services are up!"
    echo "🌐 Access the WebUI at: http://localhost:3000"

    # Open the browser automatically (only if xdg-open is available)
    if command -v xdg-open &>/dev/null; then
        echo "🌍 Opening WebUI in your browser..."
        sleep 1
        xdg-open http://localhost:3000 & disown || true
    fi

    echo -e "\n🧠 Tip: Run a model from inside the container using:"
    echo "   docker exec -it llm-app ollama run llama3"

    echo -e "\n✅ Done!"
    
    return 0
}

_install_mori_llama

exit $?
