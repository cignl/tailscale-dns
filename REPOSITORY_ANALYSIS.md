# Repository Analysis: tailscale-dns

## Overview
This repository provides a **Docker container that integrates CoreDNS with Tailscale** to create a DNS server accessible over a Tailscale network. It combines DNS management capabilities with secure networking.

## Architecture

The solution is built with three main components:

1. **CoreDNS** (v1.11.3) - DNS server with custom plugin
2. **Tailscale Plugin** (v0.3.9) - Integrates Tailscale networking into CoreDNS
3. **Tailscale Client** (unstable) - Provides secure network connectivity

## Key Files Analysis

### **Dockerfile** (Main build file)
- **Multi-stage build**:
  - Stage 1: Compiles CoreDNS from source with Tailscale plugin integration
  - Stage 2: Pulls Tailscale binaries from official image
  - Stage 3: Creates final Alpine-based image (3.19.1)
- **Key operations**:
  - Clones CoreDNS and Tailscale plugin repositories
  - Modifies `plugin.cfg` to register the Tailscale plugin
  - Uses supervisor to manage multiple processes
- **Exposed ports**: 53/udp (DNS), 41641/tcp (Tailscale)

### **supervisord.conf** (Process management)
Manages 7 programs/services:
1. `tailscale_version` - Displays Tailscale version at startup
2. `coredns_version` - Displays CoreDNS version at startup
3. `coredns_plugin` - Lists CoreDNS plugins (autostart disabled)
4. `tailscaled` - Tailscale daemon (core networking)
5. `tailscale-up` - Connection initialization wrapper
6. `coredns` - DNS server process

All services pipe logs through `log.sh` for consistent formatting.

### **tailscale-up-wrapper.sh** (Connection handler)
- Sleeps 2 seconds to allow CoreDNS initialization
- Checks if Tailscale is already authenticated
- Runs `tailscale up` with auth key if needed
- Uses `--accept-dns=false` to avoid DNS conflicts
- Keeps running via `tail -f /dev/null`

### **healthcheck.sh** (Container health monitoring)
Performs three checks:
1. Verifies `tailscaled` process is running
2. Confirms Tailscale connection status
3. Tests CoreDNS DNS query response (queries example.com)

### **log.sh** (Log formatting utility)
Simple script that prefixes each log line with a service name (e.g., `[coredns]`, `[tailscaled]`)

### **Corefile** (DNS configuration)
Current configuration:
```
.:5300 {
    tailscale ts.cignl.cc
    forward . 8.8.8.8 8.8.4.4
    health
    log
    errors
}
```
- Listens on port 5300
- Uses `ts.cignl.cc` as the Tailscale domain
- Forwards non-Tailscale queries to Google DNS
- Enables health endpoint, logging, and error reporting

### **CI/CD Pipeline** (.github/workflows/docker-publish.yml)
- Triggers on push to `release` branch
- Builds and publishes to GitHub Container Registry (ghcr.io)
- Generates artifact attestations for supply chain security
- Tagged as `ghcr.io/cignl/tailscale-dns:release`

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `TS_AUTHKEY` | unset | Tailscale authentication key (required) |
| `TS_HOSTNAME` | coredns | Hostname for Tailscale node |
| `TS_ACCEPT_DNS` | false | Whether to accept Tailscale DNS settings |

## Runtime Flow

1. Supervisor starts all configured programs
2. Version information is logged for both Tailscale and CoreDNS
3. `tailscaled` daemon starts with state persistence
4. `tailscale-up-wrapper.sh` authenticates with Tailscale network
5. CoreDNS starts with the mounted/default Corefile
6. Healthcheck runs every 30 seconds

## Observations & Notes

### Strengths
- Multi-stage build keeps final image size minimal
- Supervisor provides robust process management
- Health checks ensure service reliability
- Logging is centralized and well-formatted
- CI/CD pipeline includes modern security features (attestations)

### Potential Issues
1. **Duplicate Dockerfile**: `Dockerfile copy` exists (should probably be removed)
2. **Port mismatch**: Corefile uses port 5300, but Dockerfile exposes port 53
3. **Hardcoded domain**: Corefile has `ts.cignl.cc` instead of generic example
4. **Autorestart disabled**: All supervisor programs have `autorestart=false`, meaning they won't recover from crashes
5. **TS_AUTHKEY default**: "unset" will cause failures; should validate on startup
6. **No graceful shutdown**: Services use `SIGTERM` by default without handling

### Security Considerations
- Uses unstable Tailscale image (consider using stable releases)
- Runs as root user in supervisor
- Auth key must be provided securely (environment variable exposure risk)

## Technology Stack
- **Language**: Shell scripting, Dockerfile
- **Runtime**: Alpine Linux 3.19.1
- **Process Manager**: Supervisor
- **DNS Server**: CoreDNS 1.11.3
- **Networking**: Tailscale (unstable)
- **Build**: Multi-stage Docker, Go 1.23.1

## Conclusion

This is a well-structured project for its intended purpose, with room for improvements in error handling, configuration flexibility, and production hardening.
