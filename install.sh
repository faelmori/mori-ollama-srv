#!/usr/bin/env bash

function _install_mori_llama() {
    printf "\033[H\033[2J"

    echo "💻️ Installing dependencies..."
    sleep 2

    echo "🔧 Creating volumes..."
    docker volume create llm-ui-vol
    docker volume create llm-srv-vol

    echo "🌐 Creating networks..."
    docker network create hub-ass-priv-net --subnet=10.0.0.0/28
    docker network create hub-ass-pub-net

    echo "🚀 Starting services..."
    docker compose up -d --build --force-recreate

    echo "🌍 Opening Open WebUI..."
    sleep 1
    xdg-open http://localhost:3000 &
    
    disown || true

    return 0
  }

  _install_mori_llama

  exit $?
