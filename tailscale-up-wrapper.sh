#!/bin/sh

# Allow coredns to start first
sleep 2

# Check if Tailscale is already logged in
if tailscale status | grep -q "Logged out"; then
    echo "Tailscale is not logged in. Running tailscale up..."
    tailscale up --authkey=${TS_AUTHKEY} --accept-dns=false || { echo "Failed to log in"; exit 1; }
else
    echo "Tailscale is already logged in."
fi

# Keep the script running
tail -f /dev/null
