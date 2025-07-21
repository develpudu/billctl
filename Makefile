# Facturator - FIMAL Billing Calculator
# Makefile for build automation

# Variables
BINARY_NAME=facturator
BASH_SCRIPT=calcular_facturacion.sh
VERSION?=1.0.0
BUILD_TIME=$(shell date +%Y-%m-%d_%H:%M:%S)
GIT_COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.GitCommit=$(GIT_COMMIT)"

# Go related variables
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod

# Build output directories
BUILD_DIR=build
DIST_DIR=dist

# Supported platforms for cross-compilation
PLATFORMS=darwin/amd64 darwin/arm64 linux/amd64 linux/arm64 windows/amd64

# Colors for output
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
BLUE=\033[0;34m
NC=\033[0m # No Color

.PHONY: all build build-all test test-verbose test-coverage clean install uninstall benchmark help deps update-deps lint format check-bash cross-compile package release

# Default target
all: deps test build

# Help target
help: ## Show this help message
	@echo "$(BLUE)Facturator - FIMAL Billing Calculator$(NC)"
	@echo "$(BLUE)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Dependency management
deps: ## Download Go dependencies
	@echo "$(BLUE)Downloading dependencies...$(NC)"
	$(GOMOD) download
	$(GOMOD) tidy

update-deps: ## Update Go dependencies
	@echo "$(BLUE)Updating dependencies...$(NC)"
	$(GOGET) -u ./...
	$(GOMOD) tidy

# Build targets
build: deps ## Build the Go binary
	@echo "$(BLUE)Building $(BINARY_NAME)...$(NC)"
	$(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME) .
	@chmod +x $(BINARY_NAME)
	@echo "$(GREEN)Build completed: $(BINARY_NAME)$(NC)"

build-debug: deps ## Build with debug symbols
	@echo "$(BLUE)Building $(BINARY_NAME) with debug symbols...$(NC)"
	$(GOBUILD) -gcflags="all=-N -l" -o $(BINARY_NAME)-debug .
	@chmod +x $(BINARY_NAME)-debug
	@echo "$(GREEN)Debug build completed: $(BINARY_NAME)-debug$(NC)"

build-race: deps ## Build with race detection
	@echo "$(BLUE)Building $(BINARY_NAME) with race detection...$(NC)"
	$(GOBUILD) -race $(LDFLAGS) -o $(BINARY_NAME)-race .
	@chmod +x $(BINARY_NAME)-race
	@echo "$(GREEN)Race detection build completed: $(BINARY_NAME)-race$(NC)"

# Cross-compilation
cross-compile: deps ## Cross-compile for all supported platforms
	@echo "$(BLUE)Cross-compiling for all platforms...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@for platform in $(PLATFORMS); do \
		platform_split=($${platform//\// }); \
		GOOS=$${platform_split[0]}; \
		GOARCH=$${platform_split[1]}; \
		output_name=$(BINARY_NAME)-$${GOOS}-$${GOARCH}; \
		if [ $${GOOS} = "windows" ]; then output_name=$${output_name}.exe; fi; \
		echo "Building for $${GOOS}/$${GOARCH}..."; \
		env GOOS=$${GOOS} GOARCH=$${GOARCH} $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$${output_name} .; \
		if [ $$? -ne 0 ]; then \
			echo "$(RED)Failed to build for $${GOOS}/$${GOARCH}$(NC)"; \
			exit 1; \
		fi; \
	done
	@echo "$(GREEN)Cross-compilation completed. Binaries are in $(BUILD_DIR)/$(NC)"

# Testing
test: ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	$(GOTEST) -v ./...

test-verbose: ## Run tests with verbose output
	@echo "$(BLUE)Running tests with verbose output...$(NC)"
	$(GOTEST) -v -race ./...

test-coverage: ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	$(GOTEST) -v -race -coverprofile=coverage.out ./...
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "$(GREEN)Coverage report generated: coverage.html$(NC)"

test-bench: ## Run benchmark tests
	@echo "$(BLUE)Running benchmark tests...$(NC)"
	$(GOTEST) -bench=. -benchmem ./...

# Bash script validation
check-bash: ## Validate bash script syntax
	@echo "$(BLUE)Checking bash script syntax...$(NC)"
	@if [ -f "$(BASH_SCRIPT)" ]; then \
		bash -n $(BASH_SCRIPT) && echo "$(GREEN)Bash script syntax is valid$(NC)" || echo "$(RED)Bash script has syntax errors$(NC)"; \
	else \
		echo "$(YELLOW)Bash script not found: $(BASH_SCRIPT)$(NC)"; \
	fi
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "$(BLUE)Running shellcheck...$(NC)"; \
		shellcheck $(BASH_SCRIPT) || echo "$(YELLOW)Shellcheck found issues$(NC)"; \
	else \
		echo "$(YELLOW)shellcheck not installed, skipping additional checks$(NC)"; \
	fi

# Performance benchmarking
benchmark: build check-bash ## Run performance benchmarks comparing Go vs Bash
	@echo "$(BLUE)Running performance benchmarks...$(NC)"
	@if [ -f "benchmark.sh" ]; then \
		chmod +x benchmark.sh; \
		./benchmark.sh; \
	else \
		echo "$(RED)benchmark.sh not found$(NC)"; \
		exit 1; \
	fi

benchmark-quick: build ## Run quick performance test
	@echo "$(BLUE)Running quick benchmark...$(NC)"
	@echo "Go version:"
	@time ./$(BINARY_NAME) -m 2024-01 > /dev/null
	@echo "Bash version:"
	@if [ -f "$(BASH_SCRIPT)" ]; then \
		time ./$(BASH_SCRIPT) -m 2024-01 > /dev/null; \
	else \
		echo "$(YELLOW)Bash script not found$(NC)"; \
	fi

# Code quality
lint: ## Run linter
	@echo "$(BLUE)Running linter...$(NC)"
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "$(YELLOW)golangci-lint not installed, using go vet$(NC)"; \
		$(GOCMD) vet ./...; \
	fi

format: ## Format code
	@echo "$(BLUE)Formatting code...$(NC)"
	$(GOCMD) fmt ./...
	@if command -v goimports >/dev/null 2>&1; then \
		goimports -w .; \
	fi

# Installation
install: build ## Install binary to system
	@echo "$(BLUE)Installing $(BINARY_NAME)...$(NC)"
	@if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then \
		cp $(BINARY_NAME) /usr/local/bin/; \
		echo "$(GREEN)Installed to /usr/local/bin/$(BINARY_NAME)$(NC)"; \
	elif [ -d "$$HOME/.local/bin" ]; then \
		mkdir -p $$HOME/.local/bin; \
		cp $(BINARY_NAME) $$HOME/.local/bin/; \
		echo "$(GREEN)Installed to $$HOME/.local/bin/$(BINARY_NAME)$(NC)"; \
		echo "$(YELLOW)Make sure $$HOME/.local/bin is in your PATH$(NC)"; \
	else \
		echo "$(RED)No suitable installation directory found$(NC)"; \
		echo "$(YELLOW)Please copy $(BINARY_NAME) to a directory in your PATH manually$(NC)"; \
	fi

uninstall: ## Uninstall binary from system
	@echo "$(BLUE)Uninstalling $(BINARY_NAME)...$(NC)"
	@rm -f /usr/local/bin/$(BINARY_NAME)
	@rm -f $$HOME/.local/bin/$(BINARY_NAME)
	@echo "$(GREEN)Uninstalled $(BINARY_NAME)$(NC)"

# Packaging
package: cross-compile ## Create distribution packages
	@echo "$(BLUE)Creating distribution packages...$(NC)"
	@mkdir -p $(DIST_DIR)
	@for platform in $(PLATFORMS); do \
		platform_split=($${platform//\// }); \
		GOOS=$${platform_split[0]}; \
		GOARCH=$${platform_split[1]}; \
		binary_name=$(BINARY_NAME)-$${GOOS}-$${GOARCH}; \
		if [ $${GOOS} = "windows" ]; then binary_name=$${binary_name}.exe; fi; \
		package_name=$(BINARY_NAME)-$(VERSION)-$${GOOS}-$${GOARCH}; \
		mkdir -p $(DIST_DIR)/$${package_name}; \
		cp $(BUILD_DIR)/$${binary_name} $(DIST_DIR)/$${package_name}/; \
		cp README.md $(DIST_DIR)/$${package_name}/; \
		cp $(BASH_SCRIPT) $(DIST_DIR)/$${package_name}/ 2>/dev/null || true; \
		if [ $${GOOS} = "windows" ]; then \
			cd $(DIST_DIR) && zip -r $${package_name}.zip $${package_name}/; \
		else \
			cd $(DIST_DIR) && tar -czf $${package_name}.tar.gz $${package_name}/; \
		fi; \
		rm -rf $(DIST_DIR)/$${package_name}; \
	done
	@echo "$(GREEN)Distribution packages created in $(DIST_DIR)/$(NC)"

# Release
release: clean test package ## Prepare a release
	@echo "$(GREEN)Release $(VERSION) prepared successfully!$(NC)"
	@echo "$(BLUE)Distribution packages:$(NC)"
	@ls -la $(DIST_DIR)/

# Utility targets
version: ## Show version information
	@echo "Version: $(VERSION)"
	@echo "Build Time: $(BUILD_TIME)"
	@echo "Git Commit: $(GIT_COMMIT)"

info: ## Show project information
	@echo "$(BLUE)Project Information:$(NC)"
	@echo "  Name: Facturator"
	@echo "  Description: FIMAL Billing Calculator"
	@echo "  Version: $(VERSION)"
	@echo "  Go Version: $(shell $(GOCMD) version | cut -d' ' -f3)"
	@echo "  Build Directory: $(BUILD_DIR)"
	@echo "  Distribution Directory: $(DIST_DIR)"
	@echo "  Binary Name: $(BINARY_NAME)"
	@echo "  Supported Platforms: $(PLATFORMS)"

# Development helpers
dev: build ## Build and run with sample data
	@echo "$(BLUE)Running development test...$(NC)"
	./$(BINARY_NAME) -m 2024-01 -d 5 -h 8

run-examples: build ## Run example calculations
	@echo "$(BLUE)Running example calculations...$(NC)"
	@echo "$(YELLOW)Example 1: 120 hours$(NC)"
	./$(BINARY_NAME) -h 120
	@echo ""
	@echo "$(YELLOW)Example 2: January 2024$(NC)"
	./$(BINARY_NAME) -m 2024-01
	@echo ""
	@echo "$(YELLOW)Example 3: Combined calculation$(NC)"
	./$(BINARY_NAME) -m 01 -s 1 -d 3 -h 5

# Cleanup
clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	$(GOCLEAN)
	@rm -f $(BINARY_NAME)
	@rm -f $(BINARY_NAME)-debug
	@rm -f $(BINARY_NAME)-race
	@rm -f coverage.out coverage.html
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DIST_DIR)
	@rm -f benchmark_results.txt benchmark_report.txt
	@rm -f massif.*.out
	@echo "$(GREEN)Cleanup completed$(NC)"

clean-all: clean ## Clean everything including Go module cache
	@echo "$(BLUE)Cleaning Go module cache...$(NC)"
	$(GOCMD) clean -modcache
	@echo "$(GREEN)Complete cleanup finished$(NC)"

# CI/CD helpers
ci-test: deps lint test-coverage ## Run CI tests
	@echo "$(GREEN)CI tests completed successfully$(NC)"

ci-build: deps test build cross-compile ## Run CI build
	@echo "$(GREEN)CI build completed successfully$(NC)"

# Docker support (optional)
docker-build: ## Build Docker image
	@if [ -f "Dockerfile" ]; then \
		echo "$(BLUE)Building Docker image...$(NC)"; \
		docker build -t facturator:$(VERSION) .; \
		docker tag facturator:$(VERSION) facturator:latest; \
		echo "$(GREEN)Docker image built: facturator:$(VERSION)$(NC)"; \
	else \
		echo "$(YELLOW)Dockerfile not found$(NC)"; \
	fi

# Show build status
status: ## Show current build status
	@echo "$(BLUE)Build Status:$(NC)"
	@echo "  Binary exists: $$([ -f $(BINARY_NAME) ] && echo '$(GREEN)Yes$(NC)' || echo '$(RED)No$(NC)')"
	@echo "  Bash script exists: $$([ -f $(BASH_SCRIPT) ] && echo '$(GREEN)Yes$(NC)' || echo '$(RED)No$(NC)')"
	@echo "  Tests passing: $$($(GOTEST) ./... >/dev/null 2>&1 && echo '$(GREEN)Yes$(NC)' || echo '$(RED)No$(NC)')"
	@echo "  Dependencies up to date: $$($(GOMOD) verify >/dev/null 2>&1 && echo '$(GREEN)Yes$(NC)' || echo '$(YELLOW)Unknown$(NC)')"
