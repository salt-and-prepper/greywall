//go:build linux

package sandbox

import (
	"strings"
	"testing"
)

func TestTun2socksCommand_LongFlags(t *testing.T) {
	cmd := tun2socksCommand("socks5://user:pass@127.0.0.1:${PROXY_PORT}")

	for _, want := range []string{"--device tun0", "--proxy socks5://user:pass@127.0.0.1:${PROXY_PORT}"} {
		if !strings.Contains(cmd, want) {
			t.Errorf("tun2socks command %q is missing %q", cmd, want)
		}
	}
	// Single-dash forms are pflag shorthand clusters in tun2socks v2.6+.
	for _, bad := range []string{" -device", " -proxy"} {
		if strings.Contains(cmd, bad) {
			t.Errorf("tun2socks command %q uses the single-dash flag %q", cmd, strings.TrimSpace(bad))
		}
	}
}
