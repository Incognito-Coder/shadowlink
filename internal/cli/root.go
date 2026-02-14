package cli

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/Incognito-Coder/ShadowLink/internal/session"
)

var (
	cfgFile string
	verbose bool
)

// Execute runs the root command
func Execute(version, commit, date string) error {
	rootCmd := &cobra.Command{
		Use:   "shadowlink",
		Short: "ShadowLink - Advanced Reverse Tunnel Framework",
		Long: `ShadowLink is a high-performance reverse tunnel framework with
traffic obfuscation and DPI bypass capabilities.

Features:
  - Multiple transports (TCP, KCP, WebSocket, HTTP/HTTPS)
  - Traffic obfuscation and HTTP mimicry
  - Stream multiplexing with SMUX
  - AES-GCM encryption
  - Connection pooling and auto-reconnect
  - Production-ready with systemd integration`,
		Version: fmt.Sprintf("%s (commit: %s, built: %s)", version, commit, date),
	}

	rootCmd.PersistentFlags().StringVarP(&cfgFile, "config", "c", "", "config file path")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")

	// Add subcommands
	rootCmd.AddCommand(serverCmd())
	rootCmd.AddCommand(clientCmd())
	rootCmd.AddCommand(configCmd())
	rootCmd.AddCommand(versionCmd(version, commit, date))
	rootCmd.AddCommand(optimizeCmd())

	return rootCmd.Execute()
}

// serverCmd returns the server command
func serverCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "server",
		Short: "Run in server mode",
		Long:  "Start ShadowLink in server mode to accept incoming tunnel connections",
		RunE: func(cmd *cobra.Command, args []string) error {
			if cfgFile == "" {
				return fmt.Errorf("config file required (use -c or --config)")
			}
			return runServer(cfgFile, verbose)
		},
	}
}

// clientCmd returns the client command
func clientCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "client",
		Short: "Run in client mode",
		Long:  "Start ShadowLink in client mode to connect to server",
		RunE: func(cmd *cobra.Command, args []string) error {
			if cfgFile == "" {
				return fmt.Errorf("config file required (use -c or --config)")
			}
			return runClient(cfgFile, verbose)
		},
	}
}

// configCmd returns the config command
func configCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "config",
		Short: "Configuration management",
		Long:  "Generate, validate, and manage configuration files",
	}

	cmd.AddCommand(configGenerateCmd())
	cmd.AddCommand(configValidateCmd())

	return cmd
}

func configGenerateCmd() *cobra.Command {
	var configType string

	cmd := &cobra.Command{
		Use:   "generate",
		Short: "Generate example configuration",
		Long:  "Generate an example configuration file (server or client)",
		RunE: func(cmd *cobra.Command, args []string) error {
			return generateConfig(configType)
		},
	}

	cmd.Flags().StringVarP(&configType, "type", "t", "server", "config type (server or client)")

	return cmd
}

func configValidateCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "validate",
		Short: "Validate configuration file",
		Long:  "Validate a configuration file for errors",
		RunE: func(cmd *cobra.Command, args []string) error {
			if cfgFile == "" {
				return fmt.Errorf("config file required (use -c or --config)")
			}
			return validateConfig(cfgFile)
		},
	}
}

// versionCmd returns the version command
func versionCmd(version, commit, date string) *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print version information",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("ShadowLink version %s\n", version)
			fmt.Printf("Commit: %s\n", commit)
			fmt.Printf("Built: %s\n", date)
		},
	}
}

// optimizeCmd returns the system optimization command
func optimizeCmd() *cobra.Command {
	var profile string

	cmd := &cobra.Command{
		Use:   "optimize",
		Short: "Optimize system for ShadowLink",
		Long:  "Apply system optimizations (sysctl, BBR, etc.)",
		RunE: func(cmd *cobra.Command, args []string) error {
			return optimizeSystem(profile)
		},
	}

	cmd.Flags().StringVarP(&profile, "profile", "p", "server", "optimization profile (server or client)")

	return cmd
}

// runServer starts the server
func runServer(configFile string, verbose bool) error {
	fmt.Printf("Starting ShadowLink server with config: %s\n", configFile)
	// TODO: Implement server logic
	return fmt.Errorf("not implemented yet - see internal/session/server.go")
}

// runClient starts the client
func runClient(configFile string, verbose bool) error {
	fmt.Printf("Starting ShadowLink client with config: %s\n", configFile)
	client := &session.Client{}
	return client.Start(configFile, verbose)
}

// generateConfig generates an example configuration
func generateConfig(configType string) error {
	// TODO: Implement config generation
	fmt.Printf("Generating %s configuration...\n", configType)
	return fmt.Errorf("not implemented yet - see configs/ directory for examples")
}

// validateConfig validates a configuration file
func validateConfig(configFile string) error {
	// TODO: Implement config validation
	fmt.Printf("Validating config: %s\n", configFile)
	return fmt.Errorf("not implemented yet - see internal/config/validator.go")
}

// optimizeSystem applies system optimizations
func optimizeSystem(profile string) error {
	if os.Geteuid() != 0 {
		return fmt.Errorf("system optimization requires root privileges")
	}

	fmt.Printf("Applying %s optimizations...\n", profile)
	// TODO: Implement system optimization
	return fmt.Errorf("not implemented yet - run scripts/install.sh for full optimization")
}
