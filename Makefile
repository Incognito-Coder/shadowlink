# ShadowLink Makefile

.PHONY: all build build-all test clean install uninstall deps help

# Variables
BINARY_NAME=shadowlink
VERSION?=1.0.0
COMMIT?=$(shell git rev-parse --short HEAD 2>/dev/null || echo "dev")
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS=-ldflags "-X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(BUILD_TIME) -s -w"

# Build directories
BUILD_DIR=build
DIST_DIR=dist

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
GOINSTALL=$(GOCMD) install

# Installation directories
INSTALL_DIR=/usr/local/bin
CONFIG_DIR=/etc/shadowlink
SYSTEMD_DIR=/etc/systemd/system

all: build

## help: Display this help message
help:
	@echo "ShadowLink Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

## build: Build for current platform
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/shadowlink
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

## build-all: Build for all platforms
build-all: build-linux build-darwin build-windows

## build-linux: Build for Linux (amd64, arm64, armv7)
build-linux:
	@echo "Building for Linux..."
	@mkdir -p $(DIST_DIR)
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-linux-amd64 ./cmd/shadowlink
	GOOS=linux GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-linux-arm64 ./cmd/shadowlink
	GOOS=linux GOARCH=arm GOARM=7 $(GOBUILD) $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-linux-armv7 ./cmd/shadowlink
	@echo "Linux builds complete"

## build-darwin: Build for macOS
build-darwin:
	@echo "Building for macOS..."
	@mkdir -p $(DIST_DIR)
	GOOS=darwin GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-darwin-amd64 ./cmd/shadowlink
	GOOS=darwin GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-darwin-arm64 ./cmd/shadowlink
	@echo "macOS builds complete"

## build-windows: Build for Windows
build-windows:
	@echo "Building for Windows..."
	@mkdir -p $(DIST_DIR)
	GOOS=windows GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-windows-amd64.exe ./cmd/shadowlink
	@echo "Windows builds complete"

## test: Run tests
test:
	@echo "Running tests..."
	$(GOTEST) -v -race -coverprofile=coverage.out ./...
	@echo "Tests complete"

## test-coverage: Run tests with coverage report
test-coverage: test
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

## deps: Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOMOD) download
	$(GOMOD) tidy
	@echo "Dependencies downloaded"

## clean: Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR) $(DIST_DIR)
	rm -f coverage.out coverage.html
	@echo "Clean complete"

## install: Install binary and create configuration directories
install: build
	@echo "Installing ShadowLink..."
	install -m 755 $(BUILD_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/$(BINARY_NAME)
	mkdir -p $(CONFIG_DIR)
	mkdir -p $(CONFIG_DIR)/certs
	chmod 755 $(CONFIG_DIR)
	chmod 700 $(CONFIG_DIR)/certs
	@echo "Installation complete"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Generate config: shadowlink config generate --type server > $(CONFIG_DIR)/server.yaml"
	@echo "  2. Edit config: vi $(CONFIG_DIR)/server.yaml"
	@echo "  3. Start service: shadowlink server -c $(CONFIG_DIR)/server.yaml"

## uninstall: Uninstall ShadowLink
uninstall:
	@echo "Uninstalling ShadowLink..."
	rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	rm -rf $(CONFIG_DIR)
	rm -f $(SYSTEMD_DIR)/shadowlink-server.service
	rm -f $(SYSTEMD_DIR)/shadowlink-client.service
	systemctl daemon-reload 2>/dev/null || true
	@echo "Uninstall complete"

## install-systemd: Install systemd services
install-systemd:
	@echo "Installing systemd services..."
	install -m 644 systemd/shadowlink-server.service $(SYSTEMD_DIR)/
	install -m 644 systemd/shadowlink-client.service $(SYSTEMD_DIR)/
	systemctl daemon-reload
	@echo "Systemd services installed"
	@echo "Enable with: systemctl enable shadowlink-server"

## fmt: Format code
fmt:
	@echo "Formatting code..."
	$(GOCMD) fmt ./...
	@echo "Format complete"

## lint: Run linter
lint:
	@echo "Running linter..."
	golangci-lint run ./...
	@echo "Lint complete"

## release: Create release archives
release: build-all
	@echo "Creating release archives..."
	@mkdir -p $(DIST_DIR)/release
	cd $(DIST_DIR) && tar -czf release/$(BINARY_NAME)-$(VERSION)-linux-amd64.tar.gz $(BINARY_NAME)-linux-amd64
	cd $(DIST_DIR) && tar -czf release/$(BINARY_NAME)-$(VERSION)-linux-arm64.tar.gz $(BINARY_NAME)-linux-arm64
	cd $(DIST_DIR) && tar -czf release/$(BINARY_NAME)-$(VERSION)-linux-armv7.tar.gz $(BINARY_NAME)-linux-armv7
	cd $(DIST_DIR) && tar -czf release/$(BINARY_NAME)-$(VERSION)-darwin-amd64.tar.gz $(BINARY_NAME)-darwin-amd64
	cd $(DIST_DIR) && tar -czf release/$(BINARY_NAME)-$(VERSION)-darwin-arm64.tar.gz $(BINARY_NAME)-darwin-arm64
	cd $(DIST_DIR) && zip -q release/$(BINARY_NAME)-$(VERSION)-windows-amd64.zip $(BINARY_NAME)-windows-amd64.exe
	@echo "Release archives created in $(DIST_DIR)/release/"

## docker-build: Build Docker image
docker-build:
	@echo "Building Docker image..."
	docker build -t shadowlink:$(VERSION) .
	docker tag shadowlink:$(VERSION) shadowlink:latest
	@echo "Docker image built"

.DEFAULT_GOAL := help
