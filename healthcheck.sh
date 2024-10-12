#!/bin/sh

# Check if tailscaled is running
if ! pgrep tailscaled > /dev/null 2>&1; then
    echo "Tailscaled is not running"
    exit 1
fi

# Check if Tailscale is connected
if ! tailscale status > /dev/null 2>&1; then
    echo "Tailscale is not connected"
    exit 1
fi

# Check if CoreDNS is responding to DNS queries
if ! dig +time=1 +tries=1 @127.0.0.1 example.com > /dev/null 2>&1; then
    echo "CoreDNS is not responding"
    exit 1
fi

# If all checks pass
exit 0
