# ShadowLink

**Advanced Reverse Tunnel Framework with Traffic Obfuscation and DPI Bypass**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Go](https://img.shields.io/badge/Go-1.21+-00ADD8.svg)](https://golang.org)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)]()

---

## 📖 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage Examples](#-usage-examples)
- [Performance Tuning](#-performance-tuning)
- [DPI Bypass](#-dpi-bypass)
- [Building](#-building)
- [Contributing](#-contributing)

---

## ✨ Features

### 🚀 Core Capabilities

- **Multi-Transport Support**
  - TCP with multiplexing
  - UDP/KCP for high-throughput scenarios
  - WebSocket (WS/WSS) for firewall traversal
  - HTTP/HTTPS mimicry for deep packet inspection bypass

- **Traffic Obfuscation**
  - Random padding injection
  - Timing randomization
  - Burst mode simulation
  - Protocol fingerprint masking

- **HTTP Mimicry**
  - Realistic browser header simulation
  - Session cookie management
  - Chunked transfer encoding
  - Customizable user agents
  - Domain spoofing

- **Performance Optimization**
  - Stream multiplexing via SMUX
  - Connection pooling
  - Auto-reconnection with backoff
  - Multiple performance profiles
  - BBR congestion control support

- **Security**
  - AES-GCM encryption
  - ChaCha20-Poly1305 support
  - Pre-shared key authentication
  - TLS wrapping
  - Perfect forward secrecy ready

- **Production Ready**
  - Systemd integration
  - Structured logging
  - Metrics and monitoring
  - Graceful shutdown
  - Zero-downtime updates

---

## 🚀 Quick Start

### One-Line Installation

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Incognito-Coder/ShadowLink/main/scripts/install.sh)
```

### Manual Installation

```bash
# Download latest release
wget https://github.com/Incognito-Coder/ShadowLink/releases/latest/download/shadowlink-amd64
chmod +x shadowlink-amd64
sudo mv shadowlink-amd64 /usr/local/bin/shadowlink

# Create configuration directory
sudo mkdir -p /etc/shadowlink

# Generate example configurations
shadowlink config generate --type server > /etc/shadowlink/server.yaml
shadowlink config generate --type client > /etc/shadowlink/client.yaml
```

---

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Application Layer                      │
│         ┌──────────┐         ┌──────────┐              │
│         │  Server  │         │  Client  │              │
│         └────┬─────┘         └─────┬────┘              │
└──────────────┼─────────────────────┼────────────────────┘
               │                     │
┌──────────────┼─────────────────────┼────────────────────┐
│              │  Session Layer      │                    │
│         ┌────▼─────────────────────▼────┐              │
│         │     Session Manager           │              │
│         │  - Connection Pooling         │              │
│         │  - Load Balancing             │              │
│         │  - Auto Reconnect             │              │
│         └────┬──────────────────────────┘              │
└──────────────┼───────────────────────────────────────────┘
               │
┌──────────────┼───────────────────────────────────────────┐
│              │  Multiplexer Layer                        │
│         ┌────▼──────────────────────────┐               │
│         │   SMUX Stream Multiplexer     │               │
│         │  - Multiple streams/conn      │               │
│         │  - Flow control               │               │
│         └────┬──────────────────────────┘               │
└──────────────┼───────────────────────────────────────────┘
               │
┌──────────────┼───────────────────────────────────────────┐
│              │  Obfuscation Layer                        │
│         ┌────▼──────────────────────────┐               │
│         │    Traffic Obfuscator         │               │
│         │  - HTTP Mimicry               │               │
│         │  - Padding/Timing             │               │
│         └────┬──────────────────────────┘               │
└──────────────┼───────────────────────────────────────────┘
               │
┌──────────────┼───────────────────────────────────────────┐
│              │  Encryption Layer                         │
│         ┌────▼──────────────────────────┐               │
│         │    AES-GCM Crypto Engine      │               │
│         └────┬──────────────────────────┘               │
└──────────────┼───────────────────────────────────────────┘
               │
┌──────────────┼───────────────────────────────────────────┐
│              │  Transport Layer                          │
│         ┌────▼──────────────────────────┐               │
│         │   Transport Interface         │               │
│         ├───────────────────────────────┤               │
│         │ TCP│KCP│WS│WSS│HTTP│HTTPS    │               │
│         └───────────────────────────────┘               │
└─────────────────────────────────────────────────────────┘
```

### Component Description

**Session Manager**: Manages multiple connections, handles failover and load balancing

**Multiplexer**: Uses SMUX to multiplex multiple streams over a single connection

**Obfuscator**: Applies traffic obfuscation and HTTP mimicry to evade detection

**Crypto Engine**: Handles encryption/decryption using AES-GCM or ChaCha20-Poly1305

**Transport Layer**: Pluggable transports (TCP, KCP, WebSocket, HTTP/HTTPS)

---

## 📦 Installation

### System Requirements

- **OS**: Linux (Ubuntu 20.04+, Debian 10+, CentOS 7+), macOS, Windows
- **Architecture**: x86_64 (amd64), ARM64, ARMv7
- **RAM**: Minimum 256MB, Recommended 1GB+
- **Disk**: 50MB for binary and configs

### Automated Installation

The installer handles:
- Dependency installation
- Binary download and installation
- Directory creation
- Configuration generation
- Systemd service setup
- System optimization (optional)

```bash
# Download and run installer
wget https://raw.githubusercontent.com/Incognito-Coder/ShadowLink/main/scripts/install.sh
chmod +x install.sh
sudo ./install.sh
```

### Manual Build

```bash
# Clone repository
git clone https://github.com/Incognito-Coder/ShadowLink.git
cd shadowlink

# Build
make build

# Install
sudo make install
```

---

## ⚙️ Configuration

### Server Configuration

```yaml
mode: server
verbose: true
profile: latency

listen: 0.0.0.0:8443

transport:
  type: https
  tls:
    enabled: true
    cert_file: /etc/shadowlink/certs/cert.pem
    key_file: /etc/shadowlink/certs/key.pem

encryption:
  psk: "your-pre-shared-key-here"
  algorithm: aes-gcm

multiplexer:
  enabled: true
  keepalive: 10
  max_recv_buffer: 4194304
  max_stream_buffer: 4194304
  frame_size: 32768

obfuscation:
  enabled: true
  min_padding: 16
  max_padding: 512
  min_delay_ms: 5
  max_delay_ms: 30
  burst_chance: 0.15

http_mimic:
  enabled: true
  fake_domain: www.cloudflare.com
  fake_path: /api/v1/status
  user_agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
  chunked_encoding: true
  session_cookie: true
  custom_headers:
    - "Accept: application/json"

maps:
  - protocol: tcp
    bind: 0.0.0.0:443
    target: 127.0.0.1:443
  - protocol: udp
    bind: 0.0.0.0:51820
    target: 127.0.0.1:51820
```

### Client Configuration

```yaml
mode: client
verbose: true
profile: latency

encryption:
  psk: "your-pre-shared-key-here"
  algorithm: aes-gcm

paths:
  - transport: https
    address: server.example.com:8443
    pool_size: 3
    aggressive_pool: true
    retry_interval: 3s
    dial_timeout: 10s

multiplexer:
  enabled: true
  keepalive: 10
  max_recv_buffer: 4194304
  max_stream_buffer: 4194304

obfuscation:
  enabled: true
  min_padding: 16
  max_padding: 512
  min_delay_ms: 5
  max_delay_ms: 30

http_mimic:
  enabled: true
  fake_domain: www.cloudflare.com
  fake_path: /api/v1/status
  user_agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
  chunked_encoding: true
  session_cookie: true

transport:
  type: https
  tls:
    enabled: true
    insecure: true
```

---

## 💡 Usage Examples

### Example 1: V2Ray/Xray Tunnel with HTTP Mimicry

**Server (Iran)**
```yaml
mode: server
listen: 0.0.0.0:8443
transport:
  type: https

maps:
  - protocol: tcp
    bind: 0.0.0.0:443
    target: 127.0.0.1:10443  # V2Ray/Xray listening port
```

**Client (Foreign Server)**
```yaml
mode: client
paths:
  - transport: https
    address: iran-server.com:8443
```

Users connect to: `https://iran-server.com:443`

### Example 2: WireGuard UDP Tunnel

**Server**
```yaml
maps:
  - protocol: udp
    bind: 0.0.0.0:51820
    target: 127.0.0.1:51820
```

### Example 3: Multiple Services

**Server**
```yaml
maps:
  - protocol: tcp
    bind: 0.0.0.0:443
    target: 127.0.0.1:443    # HTTPS
  - protocol: tcp
    bind: 0.0.0.0:2222
    target: 127.0.0.1:22     # SSH
  - protocol: udp
    bind: 0.0.0.0:51820
    target: 127.0.0.1:51820  # WireGuard
```

---

## 🎯 Performance Tuning

### Performance Profiles

| Profile      | Latency | Throughput | CPU Usage | Use Case                 |
| ------------ | ------- | ---------- | --------- | ------------------------ |
| `latency`    | ⭐⭐⭐⭐⭐   | ⭐⭐⭐        | ⭐⭐⭐       | Gaming, VoIP, Real-time  |
| `balanced`   | ⭐⭐⭐     | ⭐⭐⭐⭐       | ⭐⭐⭐       | General purpose          |
| `throughput` | ⭐⭐      | ⭐⭐⭐⭐⭐      | ⭐⭐        | File transfer, bulk data |
| `gaming`     | ⭐⭐⭐⭐⭐   | ⭐⭐⭐⭐       | ⭐⭐⭐       | Low jitter gaming        |
| `lowcpu`     | ⭐⭐      | ⭐⭐⭐        | ⭐⭐⭐⭐⭐     | Resource-constrained     |

### System Optimization

The installer can automatically optimize your system:
- Enable BBR congestion control
- Tune TCP buffers
- Configure queue disciplines
- Optimize kernel parameters

Manual optimization:
```bash
sudo shadowlink optimize --profile server
```

---

## 🛡️ DPI Bypass

### HTTP/HTTPS Mimicry

ShadowLink can make traffic appear as legitimate HTTPS requests:

**Features:**
- Real browser User-Agent headers
- Session cookies with realistic patterns
- Chunked transfer encoding
- Host header spoofing (popular domains)
- Custom headers injection

**Configuration:**
```yaml
http_mimic:
  enabled: true
  fake_domain: www.google.com
  fake_path: /search
  user_agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
  chunked_encoding: true
  session_cookie: true
```

### Traffic Obfuscation

**Random Padding**: Adds random bytes to packets to mask size patterns
**Timing Randomization**: Varies packet send timing to avoid pattern detection
**Burst Mode**: Simulates real user behavior with occasional rapid sends

---

## 🔨 Building

### Build from Source

```bash
# Clone repository
git clone https://github.com/Incognito-Coder/ShadowLink.git
cd shadowlink

# Build for current platform
make build

# Build for all platforms
make build-all

# Run tests
make test

# Install
sudo make install
```

### Cross-Compilation

```bash
# Build for Linux AMD64
GOOS=linux GOARCH=amd64 make build

# Build for Linux ARM64
GOOS=linux GOARCH=arm64 make build

# Build for Windows
GOOS=windows GOARCH=amd64 make build
```

---

## 📊 Monitoring

### Logs

```bash
# Server logs
journalctl -u shadowlink-server -f

# Client logs
journalctl -u shadowlink-client -f

# Log file
tail -f /var/log/shadowlink/server.log
```

### Status

```bash
# Service status
systemctl status shadowlink-server

# Connection statistics
shadowlink status --config /etc/shadowlink/server.yaml
```

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- [xtaci/smux](https://github.com/xtaci/smux) - Stream multiplexing
- [xtaci/kcp-go](https://github.com/xtaci/kcp-go) - KCP protocol
- [gorilla/websocket](https://github.com/gorilla/websocket) - WebSocket library

---

## 📞 Support

- 🐛 [Issue Tracker](https://github.com/Incognito-Coder/ShadowLink/issues)
- 💬 [Discussions](https://github.com/Incognito-Coder/ShadowLink/discussions)
- 📖 [Documentation](https://shadowlink.readthedocs.io)

---

**ShadowLink** - *Stay invisible, stay connected*
