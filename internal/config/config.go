package config

import (
	"time"
)

// Config represents the complete configuration
type Config struct {
	Mode    string `yaml:"mode"` // "server" or "client"
	Verbose bool   `yaml:"verbose"`
	Profile string `yaml:"profile"`

	// Server-specific
	Listen string    `yaml:"listen,omitempty"`
	Maps   []PortMap `yaml:"maps,omitempty"`

	// Client-specific
	Paths []ConnectionPath `yaml:"paths,omitempty"`

	// Common settings
	Transport   TransportConfig   `yaml:"transport"`
	Encryption  EncryptionConfig  `yaml:"encryption"`
	Multiplexer MultiplexerConfig `yaml:"multiplexer"`
	Obfuscation ObfuscationConfig `yaml:"obfuscation"`
	HTTPMimic   HTTPMimicConfig   `yaml:"http_mimic,omitempty"`
	Performance PerformanceConfig `yaml:"performance"`
}

// PortMap defines a port mapping for server mode
type PortMap struct {
	Protocol string `yaml:"protocol"` // tcp, udp, both
	Bind     string `yaml:"bind"`     // IP:Port to listen on
	Target   string `yaml:"target"`   // IP:Port to forward to
}

// ConnectionPath defines a connection path for client mode
type ConnectionPath struct {
	Transport      string        `yaml:"transport"`       // tcp, kcp, ws, wss, http, https
	Address        string        `yaml:"address"`         // Server address
	PoolSize       int           `yaml:"pool_size"`       // Connection pool size
	AggressivePool bool          `yaml:"aggressive_pool"` // Aggressive pool growth
	RetryInterval  time.Duration `yaml:"retry_interval"`  // Retry interval
	DialTimeout    time.Duration `yaml:"dial_timeout"`    // Connection timeout
}

// TransportConfig holds transport-specific settings
type TransportConfig struct {
	Type string `yaml:"type"` // tcp, kcp, ws, wss, http, https

	// TLS settings (for wss, https)
	TLS TLSConfig `yaml:"tls,omitempty"`

	// KCP settings
	KCP KCPConfig `yaml:"kcp,omitempty"`

	// WebSocket settings
	WebSocket WebSocketConfig `yaml:"websocket,omitempty"`
}

// TLSConfig holds TLS configuration
type TLSConfig struct {
	Enabled  bool   `yaml:"enabled"`
	CertFile string `yaml:"cert_file,omitempty"`
	KeyFile  string `yaml:"key_file,omitempty"`
	CAFile   string `yaml:"ca_file,omitempty"`
	Insecure bool   `yaml:"insecure,omitempty"` // Skip verification
}

// KCPConfig holds KCP-specific settings
type KCPConfig struct {
	NoDelay  int `yaml:"nodelay"`  // 0:disable 1:enable
	Interval int `yaml:"interval"` // ms
	Resend   int `yaml:"resend"`   // Fast resend mode
	NC       int `yaml:"nc"`       // Congestion control
	SndWnd   int `yaml:"sndwnd"`   // Send window size
	RcvWnd   int `yaml:"rcvwnd"`   // Receive window size
	MTU      int `yaml:"mtu"`      // Maximum transmission unit
}

// WebSocketConfig holds WebSocket settings
type WebSocketConfig struct {
	ReadBufferSize  int  `yaml:"read_buffer_size"`
	WriteBufferSize int  `yaml:"write_buffer_size"`
	Compression     bool `yaml:"compression"`
}

// EncryptionConfig holds encryption settings
type EncryptionConfig struct {
	PSK       string `yaml:"psk"`       // Pre-shared key
	Algorithm string `yaml:"algorithm"` // aes-gcm, chacha20-poly1305
}

// MultiplexerConfig holds SMUX settings
type MultiplexerConfig struct {
	Enabled          bool `yaml:"enabled"`
	KeepAlive        int  `yaml:"keepalive"`         // seconds
	MaxReceiveBuffer int  `yaml:"max_recv_buffer"`   // bytes
	MaxStreamBuffer  int  `yaml:"max_stream_buffer"` // bytes
	FrameSize        int  `yaml:"frame_size"`        // bytes
	Version          int  `yaml:"version"`           // SMUX version
}

// ObfuscationConfig holds obfuscation settings
type ObfuscationConfig struct {
	Enabled     bool    `yaml:"enabled"`
	MinPadding  int     `yaml:"min_padding"`  // bytes
	MaxPadding  int     `yaml:"max_padding"`  // bytes
	MinDelay    int     `yaml:"min_delay_ms"` // milliseconds
	MaxDelay    int     `yaml:"max_delay_ms"` // milliseconds
	BurstChance float64 `yaml:"burst_chance"` // 0.0-1.0
}

// HTTPMimicConfig holds HTTP mimicry settings
type HTTPMimicConfig struct {
	Enabled         bool     `yaml:"enabled"`
	FakeDomain      string   `yaml:"fake_domain"`
	FakePath        string   `yaml:"fake_path"`
	UserAgent       string   `yaml:"user_agent"`
	ChunkedEncoding bool     `yaml:"chunked_encoding"`
	SessionCookie   bool     `yaml:"session_cookie"`
	CustomHeaders   []string `yaml:"custom_headers"`
}

// PerformanceConfig holds performance tuning settings
type PerformanceConfig struct {
	TCPNoDelay        bool `yaml:"tcp_nodelay"`
	TCPKeepAlive      int  `yaml:"tcp_keepalive"`    // seconds
	TCPReadBuffer     int  `yaml:"tcp_read_buffer"`  // bytes
	TCPWriteBuffer    int  `yaml:"tcp_write_buffer"` // bytes
	MaxConnections    int  `yaml:"max_connections"`
	CleanupInterval   int  `yaml:"cleanup_interval"`   // seconds
	SessionTimeout    int  `yaml:"session_timeout"`    // seconds
	ConnectionTimeout int  `yaml:"connection_timeout"` // seconds
	StreamTimeout     int  `yaml:"stream_timeout"`     // seconds
	MaxUDPFlows       int  `yaml:"max_udp_flows"`
	UDPFlowTimeout    int  `yaml:"udp_flow_timeout"` // seconds
	UDPBufferSize     int  `yaml:"udp_buffer_size"`  // bytes
}

// Validate validates the configuration
func (c *Config) Validate() error {
	if c.Mode != "server" && c.Mode != "client" {
		return ErrInvalidMode
	}

	if c.Mode == "server" && c.Listen == "" {
		return ErrMissingListen
	}

	if c.Mode == "client" && len(c.Paths) == 0 {
		return ErrMissingPaths
	}

	if c.Encryption.PSK == "" {
		return ErrMissingPSK
	}

	return nil
}

// IsServer returns true if running in server mode
func (c *Config) IsServer() bool {
	return c.Mode == "server"
}

// IsClient returns true if running in client mode
func (c *Config) IsClient() bool {
	return c.Mode == "client"
}
