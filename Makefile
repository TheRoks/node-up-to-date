.PHONY: help install sync dry-run test lint clean

# Default target
help: ## Show this help message
	@echo "Node.js Version Manager Sync Tool"
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  %-15s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Make the script executable and install dependencies
	@echo "Setting up node-up-to-date..."
	@chmod +x update-node.sh
	@echo "✅ Script is now executable"
	@echo "Run 'make sync' to synchronize Node.js versions"

sync: ## Synchronize NVM with supported Node.js versions
	@./update-node.sh

dry-run: ## Preview what would be done without making changes
	@./update-node.sh --dry-run

quiet: ## Run synchronization with minimal output
	@./update-node.sh --quiet

test: ## Run tests (shellcheck)
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck update-node.sh; \
		echo "✅ Script passed shellcheck"; \
	else \
		echo "❌ shellcheck not found. Install it with:"; \
		echo "  macOS: brew install shellcheck"; \
		echo "  Ubuntu/Debian: apt-get install shellcheck"; \
	fi

lint: test ## Alias for test

clean: ## Clean up log files
	@echo "Cleaning up log files..."
	@rm -f .nvm-sync.log
	@rm -f ~/.nvm-sync.log
	@echo "✅ Log files cleaned"

version: ## Show version information
	@./update-node.sh --version

# Development targets
dev-setup: ## Setup development environment
	@echo "Setting up development environment..."
	@make install
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "Installing shellcheck..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install shellcheck; \
		elif command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y shellcheck; \
		else \
			echo "Please install shellcheck manually"; \
		fi \
	fi
	@echo "✅ Development environment ready"

check: ## Run all checks
	@make test
	@echo "✅ All checks passed"
