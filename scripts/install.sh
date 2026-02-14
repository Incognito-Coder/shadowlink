#!/bin/bash

#=============================================================================
# ShadowLink - Advanced Reverse Tunnel Framework
# Installation Script
#=============================================================================

set -e

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Paths
readonly INSTALL_DIR="/usr/local/bin"
readonly CONFIG_DIR="/etc/shadowlink"
readonly SYSTEMD_DIR="/etc/systemd/system"
readonly LOG_DIR="/var/log/shadowlink"

# GitHub repository
readonly GITHUB_REPO="https://github.com/Incognito-Coder/ShadowLink"
readonly API_ENDPOINT="https://api.github.com/repos/Incognito-Coder/ShadowLink/releases/latest"

#=============================================================================
# Utility Functions
#=============================================================================

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║   _____ _    _          _____   ______          ___      _____ _   _ _  __ ║
║  / ____| |  | |   /\   |  __ \ / __ \ \        / / |    |_   _| \ | | |/ / ║
║ | (___ | |__| |  /  \  | |  | | |  | \ \  /\  / /| |      | | |  \| | ' /  ║
║  \___ \|  __  | / /\ \ | |  | | |  | |\ \/  \/ / | |      | | | . ` |  <   ║
║  ____) | |  | |/ ____ \| |__| | |__| | \  /\  /  | |____ _| |_| |\  | . \  ║
║ |_____/|_|  |_/_/    \_\_____/ \____/   \/  \/   |______|_____|_| \_|_|\_\ ║                                                                  
║                                                                            ║
║                   Advanced Reverse Tunnel Framework                        ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    else
        OS=$(uname -s)
    fi
    
    log_info "Detected OS: $OS"
}

install_dependencies() {
    log_info "Installing dependencies..."
    
    case "$OS" in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y wget curl tar openssl ca-certificates iproute2 >/dev/null 2>&1
            ;;
        centos|rhel|fedora)
            yum install -y wget curl tar openssl ca-certificates iproute >/dev/null 2>&1
            ;;
        *)
            log_warning "Unknown OS, attempting generic installation..."
            ;;
    esac
    
    log_success "Dependencies installed"
}

download_binary() {
    log_info "Fetching latest release information..."
    
    # Get latest release info
    local release_info
    release_info=$(curl -sL "$API_ENDPOINT" 2>/dev/null)
    
    if [ -z "$release_info" ]; then
        log_error "Failed to fetch release information"
        exit 1
    fi
    
    # Extract version and download URL
    local version
    version=$(echo "$release_info" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$version" ]; then
        log_warning "Could not determine latest version, using v1.0.0"
        version="v1.0.0"
    fi
    
    log_info "Latest version: ${GREEN}$version${NC}"
    
    # Determine OS and architecture
    local os arch
    case "$(uname -s)" in
        Linux)   os="linux" ;;
        Darwin)  os="darwin" ;;
        *)
            log_error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac
    case "$(uname -m)" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l)  arch="armv7" ;;
        *)       arch="amd64" ;;
    esac
    # Download binary
    local binary_url="${GITHUB_REPO}/releases/download/${version}/shadowlink-${os}-${arch}.tar.gz"
    local temp_binary="/tmp/shadowlink-${os}-${arch}.tar.gz"
    
    log_info "Downloading ShadowLink binary..."
    
    if ! wget -q --show-progress "$binary_url" -O "$temp_binary" 2>&1; then
        log_error "Failed to download binary"
        exit 1
    fi
    
    # Extract tar.gz file
    if ! tar -xzf "$temp_binary" -C /tmp 2>/dev/null; then
        log_error "Failed to extract binary"
        rm -f "$temp_binary"
        exit 1
    fi
    
    # Install binary
    chmod +x $temp_binary
    mv "/tmp/shadowlink-${os}-${arch}" "$INSTALL_DIR/shadowlink"
    
    log_success "ShadowLink binary installed to $INSTALL_DIR/shadowlink"
    
    # Verify installation
    if "$INSTALL_DIR/shadowlink" version >/dev/null 2>&1; then
        local installed_version
        installed_version=$("$INSTALL_DIR/shadowlink" version 2>&1 | head -1)
        log_info "Installed version: $installed_version"
    fi
}

create_directories() {
    log_info "Creating directories..."
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/certs"
    mkdir -p "$LOG_DIR"
    
    chmod 755 "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR/certs"
    chmod 755 "$LOG_DIR"
    
    log_success "Directories created"
}

#=============================================================================
# System Optimization
#=============================================================================

optimize_system() {
    log_info "Optimizing system for high-performance networking..."
    
    # Detect network interface
    local interface
    interface=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [ -z "$interface" ]; then
        interface="eth0"
        log_warning "Could not detect network interface, using: $interface"
    else
        log_info "Detected network interface: $interface"
    fi
    
    # Apply sysctl optimizations
    cat > /etc/sysctl.d/99-shadowlink.conf << 'EOF'
# ShadowLink Network Optimizations

# Increase TCP buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144

net.ipv4.tcp_rmem = 8192 131072 16777216
net.ipv4.tcp_wmem = 8192 131072 16777216

# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1

# Enable TCP timestamps
net.ipv4.tcp_timestamps = 1

# Enable TCP SACK
net.ipv4.tcp_sack = 1

# Reduce TCP retries
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_syn_retries = 2

# Increase connection backlog
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 1024

# Enable TCP FastOpen
net.ipv4.tcp_fastopen = 3

# Disable slow start after idle
net.ipv4.tcp_slow_start_after_idle = 0

# Disable auto-corking
net.ipv4.tcp_autocorking = 0

# Enable MTU probing
net.ipv4.tcp_mtu_probing = 1

# Optimize keepalive
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 3

# Reduce FIN timeout
net.ipv4.tcp_fin_timeout = 10

# BBR congestion control
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
EOF
    
    # Apply settings
    sysctl -p /etc/sysctl.d/99-shadowlink.conf >/dev/null 2>&1
    
    # Try to enable BBR
    if modprobe tcp_bbr 2>/dev/null; then
        log_success "BBR congestion control enabled"
    else
        log_warning "BBR not available on this system"
    fi
    
    # Configure queue discipline
    if tc qdisc add dev "$interface" root fq 2>/dev/null; then
        log_success "FQ queue discipline configured"
    else
        log_warning "Could not configure queue discipline"
    fi
    
    log_success "System optimizations applied"

    main_menu
}

#=============================================================================
# SSL Certificate Generation
#=============================================================================

generate_ssl_cert() {
    local domain="${1:-shadowlink.local}"
    
    log_info "Generating SSL certificate for domain: $domain"
    
    openssl req -x509 -newkey rsa:4096 \
        -keyout "$CONFIG_DIR/certs/key.pem" \
        -out "$CONFIG_DIR/certs/cert.pem" \
        -days 3650 -nodes \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain" \
        >/dev/null 2>&1
    
    chmod 600 "$CONFIG_DIR/certs/key.pem"
    chmod 644 "$CONFIG_DIR/certs/cert.pem"
    
    log_success "SSL certificate generated"
}

#=============================================================================
# Configuration Generation
#=============================================================================

generate_server_config() {
    local listen_port="${1:-8443}"
    local psk="${2}"
    local transport="${3:-https}"
    local bind_port="${4:-443}"
    local target_port="${5:-443}"
    
    cat > "$CONFIG_DIR/server.yaml" << EOF
mode: server
verbose: true
profile: latency

listen: 0.0.0.0:${listen_port}

transport:
  type: ${transport}
  tls:
    enabled: true
    cert_file: ${CONFIG_DIR}/certs/cert.pem
    key_file: ${CONFIG_DIR}/certs/key.pem
  kcp:
    nodelay: 1
    interval: 10
    resend: 2
    nc: 1
    sndwnd: 1024
    rcvwnd: 1024
    mtu: 1350
  websocket:
    read_buffer_size: 32768
    write_buffer_size: 32768
    compression: false

encryption:
  psk: "${psk}"
  algorithm: aes-gcm

multiplexer:
  enabled: true
  keepalive: 10
  max_recv_buffer: 4194304
  max_stream_buffer: 4194304
  frame_size: 32768
  version: 2

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
    - "Accept-Language: en-US,en;q=0.9"

performance:
  tcp_nodelay: true
  tcp_keepalive: 30
  tcp_read_buffer: 4194304
  tcp_write_buffer: 4194304
  max_connections: 10000
  cleanup_interval: 10
  session_timeout: 60
  connection_timeout: 30
  stream_timeout: 120
  max_udp_flows: 5000
  udp_flow_timeout: 180
  udp_buffer_size: 2097152

maps:
  - protocol: tcp
    bind: 0.0.0.0:${bind_port}
    target: 127.0.0.1:${target_port}
EOF
    
    log_success "Server configuration generated: $CONFIG_DIR/server.yaml"
}

generate_client_config() {
    local server_addr="${1}"
    local psk="${2}"
    local transport="${3:-https}"
    
    cat > "$CONFIG_DIR/client.yaml" << EOF
mode: client
verbose: true
profile: latency

encryption:
  psk: "${psk}"
  algorithm: aes-gcm

paths:
  - transport: ${transport}
    address: ${server_addr}
    pool_size: 3
    aggressive_pool: true
    retry_interval: 3s
    dial_timeout: 10s

multiplexer:
  enabled: true
  keepalive: 10
  max_recv_buffer: 4194304
  max_stream_buffer: 4194304
  frame_size: 32768
  version: 2

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
    - "Accept-Language: en-US,en;q=0.9"

performance:
  tcp_nodelay: true
  tcp_keepalive: 30
  tcp_read_buffer: 4194304
  tcp_write_buffer: 4194304
  max_connections: 10000
  cleanup_interval: 10
  connection_timeout: 30
  stream_timeout: 120
  udp_buffer_size: 2097152

transport:
  type: ${transport}
  tls:
    enabled: true
    insecure: true
  kcp:
    nodelay: 1
    interval: 10
    resend: 2
    nc: 1
    sndwnd: 1024
    rcvwnd: 1024
    mtu: 1350
  websocket:
    read_buffer_size: 32768
    write_buffer_size: 32768
    compression: false
EOF
    
    log_success "Client configuration generated: $CONFIG_DIR/client.yaml"
}

#=============================================================================
# Systemd Service Generation
#=============================================================================

create_systemd_service() {
    local mode="${1}" # server or client
    local service_file="$SYSTEMD_DIR/shadowlink-${mode}.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=ShadowLink Reverse Tunnel ${mode^}
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=${CONFIG_DIR}
ExecStart=${INSTALL_DIR}/shadowlink ${mode} -c ${CONFIG_DIR}/${mode}.yaml
Restart=always
RestartSec=5
StandardOutput=append:${LOG_DIR}/${mode}.log
StandardError=append:${LOG_DIR}/${mode}.log

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${CONFIG_DIR} ${LOG_DIR}

# Resource limits
LimitNOFILE=1048576
LimitNPROC=512

[Install]
WantedBy=multi-user.target
EOF
    
    chmod 644 "$service_file"
    systemctl daemon-reload
    
    log_success "Systemd service created: shadowlink-${mode}.service"
}

#=============================================================================
# Installation Modes
#=============================================================================

install_server() {
    show_banner
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              SERVER INSTALLATION                      ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Get configuration details
    read -p "Listen port for tunnel [8443]: " listen_port
    listen_port=${listen_port:-8443}
    
    read -p "PSK (leave empty to auto-generate): " psk
    if [ -z "$psk" ]; then
        psk=$(openssl rand -base64 32)
        log_info "Auto-generated PSK: ${GREEN}$psk${NC}"
    fi
    
    echo ""
    echo "Select transport:"
    echo "  1) https - HTTPS with TLS (Recommended)"
    echo "  2) http  - HTTP mimicry"
    echo "  3) wss   - WebSocket Secure"
    echo "  4) ws    - WebSocket"
    echo "  5) kcp   - KCP/UDP"
    echo "  6) tcp   - TCP"
    read -p "Choice [1-6]: " transport_choice
    
    case "$transport_choice" in
        1) transport="https" ;;
        2) transport="http" ;;
        3) transport="wss" ;;
        4) transport="ws" ;;
        5) transport="kcp" ;;
        6) transport="tcp" ;;
        *) transport="https" ;;
    esac
    
    read -p "Port to expose [443]: " bind_port
    bind_port=${bind_port:-443}
    
    read -p "Target port [443]: " target_port
    target_port=${target_port:-443}
    
    # Generate SSL certificate if needed
    if [[ "$transport" == "https" || "$transport" == "wss" ]]; then
        read -p "Domain for SSL certificate [www.cloudflare.com]: " ssl_domain
        ssl_domain=${ssl_domain:-www.cloudflare.com}
        generate_ssl_cert "$ssl_domain"
    fi
    
    # Generate configuration
    generate_server_config "$listen_port" "$psk" "$transport" "$bind_port" "$target_port"
    
    # Create systemd service
    create_systemd_service "server"
    
    # Optimize system
    read -p "Optimize system for performance? [Y/n]: " optimize
    if [[ ! "$optimize" =~ ^[Nn]$ ]]; then
        optimize_system
    fi
    
    # Enable and start service
    systemctl enable shadowlink-server
    systemctl start shadowlink-server
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}        SERVER INSTALLATION COMPLETE                   ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Configuration Details:${NC}"
    echo -e "  Listen Port: ${GREEN}$listen_port${NC}"
    echo -e "  Transport:   ${GREEN}$transport${NC}"
    echo -e "  Exposed Port: ${GREEN}$bind_port${NC}"
    echo -e "  PSK:         ${YELLOW}$psk${NC}"
    echo ""
    echo -e "${CYAN}Important:${NC} Save the PSK - you'll need it for client configuration!"
    echo ""
    echo -e "View logs: ${CYAN}journalctl -u shadowlink-server -f${NC}"
    echo -e "Status:    ${CYAN}systemctl status shadowlink-server${NC}"
    echo ""
}

install_client() {
    show_banner
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              CLIENT INSTALLATION                      ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Server address (IP:PORT): " server_addr
    
    read -p "PSK (must match server): " psk
    if [ -z "$psk" ]; then
        log_error "PSK cannot be empty!"
        exit 1
    fi
    
    echo ""
    echo "Select transport (must match server):"
    echo "  1) https - HTTPS with TLS (Recommended)"
    echo "  2) http  - HTTP mimicry"
    echo "  3) wss   - WebSocket Secure"
    echo "  4) ws    - WebSocket"
    echo "  5) kcp   - KCP/UDP"
    echo "  6) tcp   - TCP"
    read -p "Choice [1-6]: " transport_choice
    
    case "$transport_choice" in
        1) transport="https" ;;
        2) transport="http" ;;
        3) transport="wss" ;;
        4) transport="ws" ;;
        5) transport="kcp" ;;
        6) transport="tcp" ;;
        *) transport="https" ;;
    esac
    
    # Generate configuration
    generate_client_config "$server_addr" "$psk" "$transport"
    
    # Create systemd service
    create_systemd_service "client"
    
    # Optimize system
    read -p "Optimize system for performance? [Y/n]: " optimize
    if [[ ! "$optimize" =~ ^[Nn]$ ]]; then
        optimize_system
    fi
    
    # Enable and start service
    systemctl enable shadowlink-client
    systemctl start shadowlink-client
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}        CLIENT INSTALLATION COMPLETE                   ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Configuration Details:${NC}"
    echo -e "  Server:    ${GREEN}$server_addr${NC}"
    echo -e "  Transport: ${GREEN}$transport${NC}"
    echo ""
    echo -e "View logs: ${CYAN}journalctl -u shadowlink-client -f${NC}"
    echo -e "Status:    ${CYAN}systemctl status shadowlink-client${NC}"
    echo ""
}

#=============================================================================
# Main Menu
#=============================================================================

main_menu() {
    show_banner
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                   MAIN MENU                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1) Install Server"
    echo "  2) Install Client"
    echo "  3) System Optimization Only"
    echo "  4) Update ShadowLink"
    echo "  5) Uninstall"
    echo ""
    echo "  0) Exit"
    echo ""
    read -p "Select option: " choice
    
    case "$choice" in
        1) install_server ;;
        2) install_client ;;
        3) optimize_system ;;
        4) download_binary ;;
        5) uninstall ;;
        0) exit 0 ;;
        *) log_error "Invalid option"; sleep 2; main_menu ;;
    esac
}

uninstall() {
    show_banner
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
    echo -e "${RED}                   UNINSTALL                          ${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}This will remove:${NC}"
    echo "  - ShadowLink binary"
    echo "  - All configurations"
    echo "  - Systemd services"
    echo "  - System optimizations"
    echo ""
    read -p "Are you sure? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    log_info "Stopping services..."
    systemctl stop shadowlink-server 2>/dev/null || true
    systemctl stop shadowlink-client 2>/dev/null || true
    systemctl disable shadowlink-server 2>/dev/null || true
    systemctl disable shadowlink-client 2>/dev/null || true
    
    log_info "Removing files..."
    rm -f "$INSTALL_DIR/shadowlink"
    rm -rf "$CONFIG_DIR"
    rm -rf "$LOG_DIR"
    rm -f "$SYSTEMD_DIR/shadowlink-server.service"
    rm -f "$SYSTEMD_DIR/shadowlink-client.service"
    rm -f /etc/sysctl.d/99-shadowlink.conf
    
    systemctl daemon-reload
    
    log_success "ShadowLink uninstalled successfully"
    exit 0
}

#=============================================================================
# Entry Point
#=============================================================================

main() {
    check_root
    detect_os
    install_dependencies
    create_directories
    
    # Download binary if not present
    if [ ! -f "$INSTALL_DIR/shadowlink" ]; then
        download_binary
    fi
    
    main_menu
}

main "$@"
