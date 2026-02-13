package main

import (
	"fmt"
	"os"

	"github.com/Incognito-Coder/ShadowLink/internal/cli"
)

var (
	version = "0.1"
	commit  = "dev"
	date    = "unknown"
)

func main() {
	if err := cli.Execute(version, commit, date); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
