# Description: Makefile for building and managing a Docker-based LLM application
# This Makefile provides targets for setting up, running, and managing the application,
# including performance optimizations, pulling models, and cleaning up build artifacts.
# Author: Rafael Mori
# Copyright (c) 2025 Rafael Mori
# License: MIT License

APP_NAME := $(shell echo $(basename $(CURDIR)) | tr '[:upper:]' '[:lower:]')
ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Define the color codes
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_RED := \033[31m
COLOR_BLUE := \033[34m
COLOR_RESET := \033[0m

# Logging Functions
log = @printf "%b%s%b %s\n" "$(COLOR_BLUE)" "[LOG]" "$(COLOR_RESET)" "$(1)"
log_info = @printf "%b%s%b %s\n" "$(COLOR_BLUE)" "[INFO]" "$(COLOR_RESET)" "$(1)"
log_success = @printf "%b%s%b %s\n" "$(COLOR_GREEN)" "[SUCCESS]" "$(COLOR_RESET)" "$(1)"
log_warning = @printf "%b%s%b %s\n" "$(COLOR_YELLOW)" "[WARNING]" "$(COLOR_RESET)" "$(1)"
log_break = @printf "%b%s%b\n" "$(COLOR_BLUE)" "[INFO]" "$(COLOR_RESET)"
log_error = @printf "%b%s%b %s\n" "$(COLOR_RED)" "[ERROR]" "$(COLOR_RESET)" "$(1)"

ARGUMENTS := $(MAKECMDGOALS)
INSTALL_SCRIPT=$(ROOT_DIR)support/setup-dev.sh
CMD_STR := $(strip $(firstword $(ARGUMENTS)))
ARGS := $(filter-out $(strip $(CMD_STR)), $(ARGUMENTS))

perfmode:
	@echo "⚙️  Setting CPU governor to performance..."
	@if sudo -v 2>/dev/null; then \
		echo "✅ Sudo permissions granted."; \
	else \
		echo "❌ Sudo permissions required. Please run with sudo."; \
		exit 1; \
	fi
	@for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do \
		echo performance | sudo tee $$CPUFREQ; \
	done
	@echo "✅ CPU governor set to performance."

up:
	docker compose up -d --build --force-recreate

pull:
	docker exec -it llm-app ollama pull deepseek-coder:6.7b

run:
	docker exec -it llm-app ollama run deepseek-coder:6.7b

logs:
	docker logs -f llm-ui

dev: perfmode up pull
	@echo "🚀 Environment is up and optimized! Access: http://localhost:3000"

clean:
	$(call log_info, Cleaning up build artifacts)
	$(call log_info, Args: $(ARGS))
	read -p "Are you sure you want to clean up all build artifacts? (y/n): " confirm && \
	if [ "$$confirm" = "y" ]; then \
		echo "Cleaning up..."; \
		docker compose down --rmi all --volumes --remove-orphans || true; \
		rm -rf ./*-vol || true; \
		echo "Cleanup complete."; \
	else \
		echo "Cleanup aborted."; \
	fi
	$(shell exit 0)

test:
	$(call log_info, Running tests and benchmarks)
	$(call log_info, Args: $(ARGS))
	docker compose config --services | grep -q 'llm-app' && \
	@bash $(INSTALL_SCRIPT) 
	$(shell exit 0)

%:
	@:
	$(call log_info, Running command: $(CMD_STR))
	$(call log_info, Args: $(ARGS))
	@bash $(INSTALL_SCRIPT) $(CMD_STR) $(ARGS)
	$(shell exit 0)

help:
	$(call log, $(APP_NAME) Makefile)
	$(call log_break)
	$(call log, Usage:)
	$(call log,   make [target] [ARGS='--custom-arg value'])
	$(call log_break)
	$(call log, Available targets:)
	$(call log,   make dev        - Starts everything optimized and pulls the recommended model)
	$(call log,   make perfmode   - Sets CPU governor to performance mode on Linux)
	$(call log,   make up         - Starts Docker services)
	$(call log,   make pull       - Pulls the recommended model)
	$(call log,   make run        - Runs the model directly)
	$(call log,   make logs       - Shows UI logs)
	$(call log,   make clean      - Cleans build artifacts)
	$(call log,   make test       - Runs tests)
	$(call log,   make help       - Shows this help message)
	$(call log_break)
	$(call log, Usage with arguments:)
	$(call log,   make install ARGS='--custom-arg value' - Pass custom arguments to the install script)
	$(call log_break)
	$(call log, Examples:)
	$(call log,   make dev)
	$(call log,   make install ARGS='--prefix /usr/local')
	$(call log,   make up)
	$(call log,   make pull)
	$(call log,   make run)
	$(call log,   make logs)
	$(call log_break)
	$(call log, Available models:)
	$(call log,   deepseek-coder:6.7b (default) -> make dev or make pull)
	$(call log,   mistral (lightweight) -> make install ARGS='--light')
	$(call log_break)
	$(call log, For remote setup:)
	$(call log,   make install ARGS='--remote=user@remote-host')
	$(call log_break)
	$(call log, To skip benchmark:)
	$(call log,   make install ARGS='--no-benchmark')
	$(call log_break)
	$(call log, Access the UI at: http://localhost:3000)
	$(call log_break)
	$(call log, For more information, visit:)
	$(call log, 'https://github.com/rafa-mori/'$(APP_NAME))
	$(call log_break)
	$(call log_success, End of help message)
	$(shell exit 0)
