FROM golang:1.23.1-alpine3.20 AS build

WORKDIR /go/src/coredns

RUN apk add git make && \
    git clone --depth 1 --branch=v1.11.3 https://github.com/coredns/coredns /go/src/coredns && cd plugin

RUN git clone --depth 1 --branch=v0.3.9 https://github.com/damomurf/coredns-tailscale /go/src/coredns/plugin/tailscale

RUN cd plugin && \
    rm tailscale/go.mod tailscale/go.sum &&  \
    sed -i s/forward:forward/tailscale:tailscale\\nforward:forward/ /go/src/coredns/plugin.cfg && \
    cat /go/src/coredns/plugin.cfg && \
    cd .. && \
    make check && \
    go build

# Use Tailscale's unstable image as a build stage to copy binaries from
FROM tailscale/tailscale:unstable AS tailscale

FROM alpine:3.19.1
RUN apk add --no-cache iptables ca-certificates supervisor

# Copy Tailscale
COPY --from=tailscale /usr/local/bin/tailscale /usr/local/bin/tailscale
COPY --from=tailscale /usr/local/bin/tailscaled /usr/local/bin/tailscaled
RUN mkdir -p /var/lib/tailscale /var/run/tailscale

## Copy coredns
COPY --from=build /go/src/coredns/coredns /usr/local/bin
COPY Corefile /


## Copy coredns settings and scheduler stuff
COPY Corefile /etc/coredns/Corefile
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY healthcheck.sh log.sh /
COPY tailscale-up-wrapper.sh /usr/local/bin/tailscale-up-wrapper.sh

RUN chmod +x /usr/local/bin/tailscale-up-wrapper.sh
RUN chmod +x /healthcheck.sh
RUN chmod +x /log.sh

# Expose necessary ports (53 for DNS, 41641 for Tailscale)
EXPOSE 53/udp
EXPOSE 41641/tcp
VOLUME ["/etc/coredns"]

# Set default ENV
ENV TS_AUTHKEY=unset
ENV TS_HOSTNAME=coredns
ENV TS_ACCEPT_DNS=false

# Add healthcheck for Tailscale and CoreDNS
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD /bin/sh /healthcheck.sh

# Start supervisor to manage both services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]