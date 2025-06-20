#!/usr/bin/env bash
# Build: 2025-06-20 15:43:06

set -euo pipefail

# === CONFIG ================================
PROJECT_NAME="mori-ollama-srv"
DEFAULT_MODEL="deepseek-coder:6.7b"
LIGHT_MODEL="mistral"
WEBUI_PORT=3000
OLLAMA_PORT=11434
WEBUI_URL="http://localhost:$WEBUI_PORT"
PROMPT_TEST="Write a 'Hello World' in Go."
# ===========================================

# === FLAGS ================================
USE_LIGHT=false
RUN_MODE=local
REMOTE_HOST=""
DO_BENCHMARK=true
# ===========================================

_SUCCESS="\033[0;32m"
_WARN="\033[0;33m"
_ERROR="\033[0;31m"
_INFO="\033[0;36m"
_NC="\033[0m"

log() {
  local type=${1:-info}
  local message=${2:-}
  case $type in
    info|_INFO|-i|-I)
      printf '%b[_INFO]%b ℹ️  %s\n' "$_INFO" "$_NC" "$message"
      ;;
    warn|_WARN|-w|-W)
      printf '%b[_WARN]%b ⚠️  %s\n' "$_WARN" "$_NC" "$message"
      ;;
    error|_ERROR|-e|-E)
      printf '%b[_ERROR]%b ❌  %s\n' "$_ERROR" "$_NC" "$message"
      ;;
    success|_SUCCESS|-s|-S)
      printf '%b[_SUCCESS]%b ✅  %s\n' "$_SUCCESS" "$_NC" "$message"
      ;;
    *)
      printf '%b[_INFO]%b ℹ️  %s\n' "$_INFO" "$_NC" "$message"
      ;;
  esac
}

clear_screen() {
  printf "\033[H\033[2J"
}

get_current_shell() {
  local shell_proc
  shell_proc=$(cat /proc/$$/comm)
  case "${0##*/}" in
    ${shell_proc}*)
      local shebang
      shebang=$(head -1 "$0")
      printf '%s\n' "${shebang##*/}"
      ;;
    *)
      printf '%s\n' "$shell_proc"
      ;;
  esac
}

# Create a temporary directory for cache
_TEMP_DIR="${_TEMP_DIR:-$(mktemp -d)}"
if [[ -d "${_TEMP_DIR}" ]]; then
    log info "Temporary directory created: ${_TEMP_DIR}"
else
    log error "Failed to create temporary directory."
fi

clear_script_cache() {
  trap - EXIT HUP INT QUIT ABRT ALRM TERM
  if [[ ! -d "${_TEMP_DIR}" ]]; then
    exit 0
  fi
  rm -rf "${_TEMP_DIR}" || true
  if [[ -d "${_TEMP_DIR}" ]] && sudo -v 2>/dev/null; then
    sudo rm -rf "${_TEMP_DIR}"
    if [[ -d "${_TEMP_DIR}" ]]; then
      log error "Failed to remove temporary directory: ${_TEMP_DIR}"
    else
      log success "Temporary directory removed: ${_TEMP_DIR}"
    fi
  fi
  exit 0
}

set_trap() {
  local current_shell=""
  current_shell=$(get_current_shell)
  case "${current_shell}" in
    *ksh|*zsh|*bash)
      declare -a FULL_SCRIPT_ARGS=("$@")
      if [[ "${FULL_SCRIPT_ARGS[*]}" =~ -d ]]; then
          set -x
      fi
      if [[ "${current_shell}" == "bash" ]]; then
        set -o errexit
        set -o pipefail
        set -o errtrace
        set -o functrace
        shopt -s inherit_errexit
      fi
      trap 'clear_script_cache' EXIT HUP INT QUIT ABRT ALRM TERM
      ;;
  esac
}

print_banner() {
cat << "EOF"
███╗   ███╗ ██████╗ ██████╗ ██╗
████╗ ████║██╔═══██╗██╔══██╗██║
██╔████╔██║██║   ██║██████╔╝██║
██║╚██╔╝██║██║   ██║██╔══██╗██║
██║ ╚═╝ ██║╚██████╔╝██║  ██║██║
╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ⚙️ Ollama Dev Setup
EOF
}

parse_args() {
  for arg in "$@"; do
    case $arg in
      --light) USE_LIGHT=true ;;
      --remote=*) RUN_MODE=remote; REMOTE_HOST="${arg#*=}" ;;
      --no-benchmark) DO_BENCHMARK=false ;;
    esac
  done
}

set_cpu_performance_mode() {
  log info "Setting CPU governor to performance..."
  for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | sudo tee "$CPUFREQ" >/dev/null
  done
  log success "CPU set to performance mode."
}

check_containers() {
  log info "Checking container health..."
  unhealthy=$(docker ps --filter health=unhealthy --format "{{.Names}}")
  if [[ -n "$unhealthy" ]]; then
    log warn "Found unhealthy containers: $unhealthy"
    docker restart "$unhealthy"
  fi
}

start_services() {
  log info "Starting Docker Compose..."
  docker compose -p "$PROJECT_NAME" up -d --build --force-recreate
  sleep 2
  check_containers
}

pull_model() {
  local MODEL_NAME=$1
  log info "Pulling model: $MODEL_NAME..."
  docker exec -i "${PROJECT_NAME}-llm-app-1" ollama pull "$MODEL_NAME"
}

run_benchmark() {
  local MODEL_NAME=$1
  log info "Benchmarking model response time..."
  time curl -s "http://localhost:$OLLAMA_PORT/api/generate" -d '{
    "model": "'"$MODEL_NAME"'",
    "prompt": "'"$PROMPT_TEST"'"
  }' | jq -r '.response'
}

create_docker_volumes() {
  log info "Creating Docker volumes..."
  if ! test -d "$(realpath ./)/llm-ui-vol"; then
    log info "Creating llm-ui-vol directory..."
    mkdir -p "$(realpath ./)/llm-ui-vol"
  fi

  if docker volume ls | grep -q "llm-ui-vol"; then
    log warn "Volume 'llm-ui-vol' already exists, skipping creation."
  else
    docker volume create --driver local --opt type=none --opt device="$(realpath ./)/llm-ui-vol" --opt o=bind "llm-ui-vol"
  fi

  if ! test -d "$(realpath ./)/llm-app-vol"; then
    log info "Creating llm-app-vol directory..."
    mkdir -p "$(realpath ./)/llm-app-vol"
  fi

  if docker volume ls | grep -q "llm-app-vol"; then
    log warn "Volume 'llm-app-vol' already exists, skipping creation."
  else
    docker volume create --driver local --opt type=none --opt device="$(realpath ./)/llm-app-vol" --opt o=bind "llm-app-vol"
  fi

  return 0
}


open_webui() {
  if command -v xdg-open &>/dev/null; then
    log info "Opening WebUI at $WEBUI_URL"
    xdg-open "$WEBUI_URL" & disown
  else
    log info "Access WebUI at: $WEBUI_URL"
  fi
}

run_local_stack() {
  print_banner
  parse_args "$@"
  set_cpu_performance_mode

  MODEL_NAME=$([ "$USE_LIGHT" = true ] && echo "$LIGHT_MODEL" || echo "$DEFAULT_MODEL")

  start_services
  pull_model "$MODEL_NAME"

  if [ "$DO_BENCHMARK" = true ]; then
    run_benchmark "$MODEL_NAME"
  fi

  open_webui
  log success "Ready! Model '$MODEL_NAME' is up and running."
}

run_remote_stack() {
  # shellcheck disable=SC2029
  ssh "$REMOTE_HOST" 'bash -s' < "$0" "${@/--remote=*/}"
}

main() {
  case "$(get_current_shell)" in
    *ksh|*zsh|*bash)
      set_trap "$@"
      ;;
    *)
      log error "Unsupported shell: $(get_current_shell)"
      exit 1
      ;;
  esac
  clear_screen
  case "$RUN_MODE" in
    help|-h|--help)
      echo "Usage: $0 [--light] [--remote=<host>] [--no-benchmark]"
      echo "Commands:"
      echo "  start               Start the Mori Ollama stack"
      echo "  stop                Stop the Mori Ollama stack"
      echo "  restart             Restart the Mori Ollama stack"
      echo "  status              Show the status of running containers"
      echo "  logs                Show logs of running containers"
      echo "  health-check        Check the health of running containers"
      echo "  create-volumes      Create necessary Docker volumes"
      echo "  local               Run the stack locally (default)"
      echo "  remote              Run the stack on a remote host"
      echo "  benchmark           Run a benchmark on the default model ($DEFAULT_MODEL)"
      echo "  help                Show this help message"
      echo "Options:"
      echo "  --light              Use a lighter model (default: $LIGHT_MODEL)"
      echo "  --remote=<host>     Run setup on a remote host via SSH"
      echo "  --no-benchmark       Skip the benchmark step"
      return 0
      ;;
    start|--start)
      log info "Starting the Mori Ollama stack..."
      run_local_stack "$@"
      return $?
      ;;
    stop|--stop)
      log info "Stopping the Mori Ollama stack..."
      docker compose -p "$PROJECT_NAME" down
      log success "Stack stopped."
      return $?
      ;;
    restart|--restart)
      log info "Restarting the Mori Ollama stack..."
      docker compose -p "$PROJECT_NAME" down
      sleep 1
      run_local_stack "$@"
      return $?
      ;;
    status|--status)
      log info "Checking status of running containers..."
      docker ps --filter "name=$PROJECT_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
      return $?
      ;;
    logs|--logs)
      docker compose logs -f "$PROJECT_NAME"
      return $?
      ;;
    remote|--remote=*)
      run_remote_stack "$@"
      return $?
      ;;
    local|--local)
      run_local_stack "$@"
      return $?
      ;;
    benchmark|--benchmark)
      run_benchmark "$DEFAULT_MODEL"
      return $?
      ;;
    health-check|--health-check)
      check_containers
      return $?
      ;;
    create-volumes|--create-volumes)
      create_docker_volumes
      return $?
      ;;
    *)
      log error "Invalid run mode: $RUN_MODE"
      return 1
      ;;
  esac
}

main "$@"

exit $?