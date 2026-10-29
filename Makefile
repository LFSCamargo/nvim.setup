SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: help deps doctor install plugins parsers tools validate update upgrade capture bump check
help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' Makefile

deps: ## Install macOS/Linux system dependencies (may need sudo)
	@bash scripts/deps.sh

doctor: ## Check system prerequisites and optional agent CLIs
	@bash scripts/doctor.sh

install: ## Back up local config, install pinned plugins, tools, parsers; validate
	@bash scripts/install.sh

plugins: ## Install/restore plugin versions recorded in lazy-lock.json
	@bash scripts/plugins.sh restore

parsers: ## Install/update all configured Tree-sitter syntax parsers
	@bash -c 'source scripts/common.sh; run_lua "$$CONFIG_DIR/scripts/install-parsers.lua"'

tools: ## Install missing language servers, formatters and debuggers
	@bash -c 'source scripts/common.sh; run_lua "$$CONFIG_DIR/scripts/install-tools.lua"'

validate: ## Validate the installed config, plugins, parsers and tools
	@bash scripts/validate.sh

update: ## Pull this repo (fast-forward only), then install and validate
	@bash scripts/update.sh

upgrade: ## Upgrade plugins, refresh parsers, validate and save the new lockfile
	@bash scripts/plugins.sh upgrade
	@bash -c 'source scripts/common.sh; run_lua "$$CONFIG_DIR/scripts/install-parsers.lua"'
	@bash scripts/validate.sh
	@bash -c 'source scripts/common.sh; cp "$$CONFIG_DIR/lazy-lock.json" "$$SETUP_ROOT/nvim/lazy-lock.json"'

capture: ## Copy local configuration changes back into this repository
	@bash scripts/capture.sh

bump: ## Set the setup release version: make bump VERSION=1.2.3
	@bash scripts/bump.sh "$(VERSION)"

check: ## Check shell syntax and compile every Lua file without running it
	@bash scripts/check.sh
