# Tailscale DNS Docker Container

This Docker container is built to run [CoreDNS](https://github.com/coredns/coredns) with the [Tailscale plugin](https://github.com/damomurf/coredns-tailscale) and the latest Tailscale client. It allows you to manage DNS queries over a secure Tailscale network, leveraging Tailscale's secure networking capabilities.

## Docker Image

The Docker image is published at: ghcr.io/cignl/tailscale-dns:release


## Features

- CoreDNS for flexible DNS management.
- Tailscale plugin for seamless integration with Tailscale.
- Latest Tailscale client for secure networking.

## Getting Started

### Prerequisites

- Docker installed on your machine.
- A Tailscale account.
- Your own domain (e.g. example.com)

### Acquiring Your Tailscale API Key

To use the Tailscale plugin, you'll need to acquire an **auth key**. Follow these steps:

1. Log in to your [Tailscale admin console](https://login.tailscale.com/admin).
2. Navigate to the **Keys** section.
3. Click on **Generate New Key**.
4. Set the key to have the appropriate permissions (e.g., "Device" or "Admin").
5. Copy the generated key and keep it safe.

### Usage

You can run the container using Docker Compose, mounting your CoreDNS configuration file (`Corefile`).

Here's a sample `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  tailscale-dns:
    image: ghcr.io/cignl/tailscale-dns:release
    restart: always
    environment:
      - TS_AUTHKEY=<your-tailscale-auth-key>  # Replace with your Tailscale auth key
    volumes:
      - ./path/to/your/Corefile:/etc/coredns/Corefile  # Mount your Corefile
    ports:
      - "53:53/tcp"  # TCP DNS
      - "53:53/udp"  # UDP DNS
```

Here's a sample `Corefile` file:

```txt
. {
    tailscale internal.example.com
    log
    errors
    forward . 8.8.8.8
}
```

### Try it

```bash
docker-compose up -d
```
Your Tailscale DNS service should now be running and accessible on port 53 (depending on your docker-compose config)

```bash
dig +time=1 +tries=1 @127.0.0.1 tailnetmachine.example.com
```