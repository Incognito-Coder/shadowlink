# ShadowLink - Build & Development Guide

## Table of Contents

1. [Development Setup](#development-setup)
2. [Building from Source](#building-from-source)
3. [Testing](#testing)
4. [Deployment](#deployment)
5. [GitHub Release Workflow](#github-release-workflow)
6. [Architecture Deep Dive](#architecture-deep-dive)

---

## Development Setup

### Prerequisites

- **Go 1.21+**: Download from https://golang.org/dl/
- **Git**: For version control
- **Make**: Build automation
- **GCC**: For CGO dependencies (KCP)

### Clone and Setup

```bash
# Clone repository
git clone https://github.com/Incognito-Coder/ShadowLink.git
cd shadowlink

# Download dependencies
make deps

# Verify setup
go version
make help
```

### Development Tools (Optional)

```bash
# Install linter
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Install air for live reload
go install github.com/cosmtrek/air@latest
```

---

## Building from Source

### Quick Build

```bash
# Build for current platform
make build

# Output: build/shadowlink
```

### Cross-Platform Build

```bash
# Build for all platforms
make build-all

# Build specific platform
GOOS=linux GOARCH=amd64 make build
GOOS=darwin GOARCH=arm64 make build
GOOS=windows GOARCH=amd64 make build
```

### Supported Platforms

| OS      | Architecture | Binary Name                  |
| ------- | ------------ | ---------------------------- |
| Linux   | amd64        | shadowlink-linux-amd64       |
| Linux   | arm64        | shadowlink-linux-arm64       |
| Linux   | armv7        | shadowlink-linux-armv7       |
| macOS   | amd64        | shadowlink-darwin-amd64      |
| macOS   | arm64        | shadowlink-darwin-arm64      |
| Windows | amd64        | shadowlink-windows-amd64.exe |

### Build with Custom Flags

```bash
# Build with version info
VERSION=1.2.0 make build

# Build with optimization
go build -ldflags="-s -w" -o shadowlink ./cmd/shadowlink
```

---

## Testing

### Run Tests

```bash
# All tests
make test

# Specific package
go test ./internal/transport/...

# With coverage
make test-coverage

# View coverage report
open coverage.html
```

### Benchmark Tests

```bash
# Run benchmarks
go test -bench=. ./...

# Specific benchmark
go test -bench=BenchmarkEncryption ./internal/crypto/
```

### Integration Tests

```bash
# Run integration tests (requires Docker)
./scripts/integration-test.sh
```

---

## Deployment

### Manual Deployment

```bash
# Build
make build

# Install
sudo make install

# Create config
sudo mkdir -p /etc/shadowlink
shadowlink config generate --type server > /etc/shadowlink/server.yaml

# Edit config
sudo vi /etc/shadowlink/server.yaml

# Run manually
sudo shadowlink server -c /etc/shadowlink/server.yaml
```

### Systemd Deployment

```bash
# Install with systemd support
sudo make install
sudo make install-systemd

# Enable and start
sudo systemctl enable shadowlink-server
sudo systemctl start shadowlink-server

# Check status
sudo systemctl status shadowlink-server

# View logs
journalctl -u shadowlink-server -f
```

### Docker Deployment

```bash
# Build image
make docker-build

# Run server
docker run -d \
  --name shadowlink-server \
  -v /etc/shadowlink:/etc/shadowlink \
  -p 8443:8443 \
  shadowlink:latest server -c /etc/shadowlink/server.yaml
```

---

## GitHub Release Workflow

### Automated Release (Recommended)

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Build
        run: |
          make build-all
          make release
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: dist/release/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Manual Release

```bash
# Tag version
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Build all platforms
make build-all

# Create release archives
make release

# Upload to GitHub
# Use GitHub web interface or gh CLI:
gh release create v1.0.0 dist/release/* --title "v1.0.0" --notes "Release notes"
```

### Release Checklist

- [ ] Update version in `cmd/shadowlink/main.go`
- [ ] Update CHANGELOG.md
- [ ] Run full test suite: `make test`
- [ ] Build all platforms: `make build-all`
- [ ] Test on target platforms
- [ ] Create and push git tag
- [ ] Upload binaries to GitHub Release
- [ ] Update documentation if needed

---

## Architecture Deep Dive

### Module Overview

```
shadowlink/
├── cmd/shadowlink/          # Main entry point
├── internal/
│   ├── config/              # Configuration management
│   │   ├── config.go        # Config structures
│   │   ├── loader.go        # YAML loading
│   │   ├── validator.go     # Validation logic
│   │   └── profiles.go      # Performance profiles
│   │
│   ├── transport/           # Transport layer
│   │   ├── transport.go     # Interface definition
│   │   ├── tcp.go           # TCP implementation
│   │   ├── udp.go           # UDP/KCP implementation
│   │   ├── websocket.go     # WebSocket (WS/WSS)
│   │   ├── http.go          # HTTP/HTTPS mimicry
│   │   └── factory.go       # Transport factory
│   │
│   ├── multiplexer/         # Stream multiplexing
│   │   ├── multiplexer.go   # Interface
│   │   ├── smux.go          # SMUX implementation
│   │   └── pool.go          # Connection pool
│   │
│   ├── obfuscation/         # Traffic obfuscation
│   │   ├── obfuscator.go    # Interface
│   │   ├── padding.go       # Random padding
│   │   ├── timing.go        # Timing randomization
│   │   └── mimicry.go       # HTTP mimicry
│   │
│   ├── session/             # Session management
│   │   ├── manager.go       # Session manager
│   │   ├── server.go        # Server logic
│   │   └── client.go        # Client logic
│   │
│   ├── tunnel/              # Tunnel logic
│   │   ├── tunnel.go        # Interface
│   │   ├── tcp_tunnel.go    # TCP tunnel
│   │   ├── udp_tunnel.go    # UDP tunnel
│   │   └── manager.go       # Tunnel manager
│   │
│   ├── crypto/              # Encryption
│   │   ├── crypto.go        # Interface
│   │   └── aes.go           # AES-GCM
│   │
│   └── logger/              # Logging
│       └── logger.go        # Structured logger
│
└── pkg/util/                # Utilities
    ├── network.go           # Network helpers
    ├── retry.go             # Retry logic
    └── metrics.go           # Metrics
```

### Transport Layer Implementation

Each transport implements the `Transport` interface:

```go
type Transport interface {
    Dial(ctx context.Context, addr string) (net.Conn, error)
    Listen(ctx context.Context, addr string) (net.Listener, error)
    Name() string
    IsSecure() bool
    SupportsUDP() bool
}
```

**TCP Transport**: Standard TCP with optional TLS wrapping
**KCP Transport**: UDP-based with FEC and ARQ
**WebSocket**: HTTP upgrade to WebSocket (WS/WSS)
**HTTP Mimicry**: Disguised as HTTPS traffic with realistic headers

### Obfuscation Implementation

**Padding Layer**: Adds random bytes (min/max configurable)
**Timing Layer**: Introduces random delays between packets
**HTTP Mimicry**: 
  - Realistic User-Agent strings
  - Session cookies
  - Chunked transfer encoding
  - Custom headers

### Session Management

**Server Side**:
1. Accept connections on listen port
2. Decrypt and validate PSK
3. Create session for each client
4. Route traffic to target ports

**Client Side**:
1. Connect to server(s)
2. Establish session with PSK
3. Maintain connection pool
4. Auto-reconnect on failure

### Connection Pool Strategy

**Modes**:
- **Balanced**: Fixed pool size, round-robin
- **Aggressive**: Dynamic scaling based on load
- **Conservative**: Minimal connections, failover only

**Algorithm**:
```
if connection_lost:
    retry with exponential backoff
    switch to backup path if available
    
if high_load and aggressive_mode:
    spawn additional connection
    
periodic health_check:
    remove dead connections
    rebalance load
```

---

## Performance Optimization

### Profile-Based Configuration

**Latency Profile**:
- Small buffers (32KB-128KB)
- Aggressive keepalive (5s)
- TCP_NODELAY enabled
- Minimal padding

**Throughput Profile**:
- Large buffers (4MB-16MB)
- Batch processing
- Connection pooling
- Relaxed timeouts

**Gaming Profile**:
- Ultra-low latency
- Priority queuing
- Jitter reduction
- Minimal obfuscation

### System Tuning

See `scripts/install.sh` for full system optimization:
- BBR congestion control
- TCP buffer tuning
- Queue discipline (fq_codel)
- sysctl optimizations

---

## Debugging

### Enable Verbose Logging

```yaml
verbose: true
```

### Debug Build

```bash
go build -gcflags="all=-N -l" -o shadowlink-debug ./cmd/shadowlink
```

### Profiling

```bash
# CPU profiling
go test -cpuprofile=cpu.prof -bench=. ./...
go tool pprof cpu.prof

# Memory profiling
go test -memprofile=mem.prof -bench=. ./...
go tool pprof mem.prof
```

---

## Contributing

### Code Style

- Follow Go best practices
- Use `gofmt` for formatting
- Run `golangci-lint` before committing
- Write tests for new features

### Pull Request Process

1. Fork the repository
2. Create feature branch
3. Write tests
4. Update documentation
5. Submit PR with clear description

---

## License

MIT License - See LICENSE file for details

---

**For questions or support**: https://github.com/Incognito-Coder/ShadowLink/issues
