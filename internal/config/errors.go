package config

import "errors"

// Configuration errors
var (
	ErrInvalidMode   = errors.New("invalid mode: must be 'server' or 'client'")
	ErrMissingListen = errors.New("missing listen address for server mode")
	ErrMissingPaths  = errors.New("missing connection paths for client mode")
	ErrMissingPSK    = errors.New("missing pre-shared key (PSK)")
	ErrInvalidConfig = errors.New("invalid configuration")
	ErrLoadConfig    = errors.New("failed to load configuration")
)

// Default values
const (
	DefaultListenPort = "8443"
	DefaultPoolSize   = 3
	DefaultMTU        = 1350
	DefaultFrameSize  = 32768

	// Profile names
	ProfileBalanced   = "balanced"
	ProfileLatency    = "latency"
	ProfileThroughput = "throughput"
	ProfileGaming     = "gaming"
	ProfileLowCPU     = "lowcpu"
)

// Transport types
const (
	TransportTCP   = "tcp"
	TransportKCP   = "kcp"
	TransportWS    = "ws"
	TransportWSS   = "wss"
	TransportHTTP  = "http"
	TransportHTTPS = "https"
)

// Encryption algorithms
const (
	AlgoAESGCM       = "aes-gcm"
	AlgoChaCha20Poly = "chacha20-poly1305"
)
