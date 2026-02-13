package transport

import (
	"context"
	"net"
	"time"
)

// Transport defines the interface for all transport implementations
type Transport interface {
	// Dial establishes a connection to the remote address
	Dial(ctx context.Context, addr string) (net.Conn, error)

	// Listen starts listening on the specified address
	Listen(ctx context.Context, addr string) (net.Listener, error)

	// Name returns the transport name
	Name() string

	// IsSecure indicates if the transport provides built-in encryption
	IsSecure() bool

	// SupportsUDP indicates if the transport can handle UDP traffic
	SupportsUDP() bool
}

// Config holds transport configuration
type Config struct {
	// Type of transport (tcp, kcp, ws, wss, http, https)
	Type string

	// TLS configuration
	TLS *TLSConfig

	// KCP configuration
	KCP *KCPConfig

	// WebSocket configuration
	WebSocket *WebSocketConfig

	// HTTP Mimicry configuration
	HTTPMimic *HTTPMimicConfig

	// Timeout settings
	DialTimeout  time.Duration
	ReadTimeout  time.Duration
	WriteTimeout time.Duration

	// Buffer sizes
	ReadBufferSize  int
	WriteBufferSize int
}

// TLSConfig holds TLS settings
type TLSConfig struct {
	Enabled  bool
	CertFile string
	KeyFile  string
	CAFile   string
	Insecure bool // Skip verification
}

// KCPConfig holds KCP-specific settings
type KCPConfig struct {
	NoDelay  int
	Interval int
	Resend   int
	NC       int
	SndWnd   int
	RcvWnd   int
	MTU      int
}

// WebSocketConfig holds WebSocket settings
type WebSocketConfig struct {
	ReadBufferSize  int
	WriteBufferSize int
	Compression     bool
}

// HTTPMimicConfig holds HTTP mimicry settings
type HTTPMimicConfig struct {
	Enabled         bool
	FakeDomain      string
	FakePath        string
	UserAgent       string
	ChunkedEncoding bool
	SessionCookie   bool
	CustomHeaders   []string
}

// DefaultConfig returns a default transport configuration
func DefaultConfig() *Config {
	return &Config{
		Type:            "tcp",
		DialTimeout:     10 * time.Second,
		ReadTimeout:     60 * time.Second,
		WriteTimeout:    60 * time.Second,
		ReadBufferSize:  4194304, // 4MB
		WriteBufferSize: 4194304, // 4MB
	}
}
