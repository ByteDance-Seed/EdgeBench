# Reverse Proxy Setup for CAS Factory Server

This guide covers deploying CAS Factory Server behind a reverse proxy with TLS termination.

## Overview

The Factory Server uses WebSocket connections for real-time terminal multiplexing. When running behind a reverse proxy, special configuration is needed to:

1. Upgrade HTTP connections to WebSocket
2. Pass client IP addresses correctly
3. Handle long-lived connections without timeout
4. Terminate TLS at the proxy

## Nginx Configuration

### Basic WebSocket Proxy

```nginx
# /etc/nginx/sites-available/cas-factory

upstream cas_factory {
    server 127.0.0.1:8765;
    keepalive 32;
}

server {
    listen 443 ssl http2;
    server_name factory.example.com;

    # TLS Configuration
    ssl_certificate /etc/letsencrypt/live/factory.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/factory.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://cas_factory;
        proxy_http_version 1.1;

        # WebSocket upgrade headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Pass client IP to backend
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;

        # Timeouts for long-lived WebSocket connections
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;

        # Disable buffering for real-time terminal output
        proxy_buffering off;
        proxy_cache off;

        # Keepalive
        proxy_socket_keepalive on;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name factory.example.com;
    return 301 https://$server_name$request_uri;
}
```

### Key Nginx Settings Explained

| Setting | Purpose |
|---------|---------|
| `proxy_http_version 1.1` | Required for WebSocket upgrade |
| `Upgrade $http_upgrade` | Pass WebSocket upgrade header |
| `Connection "upgrade"` | Keep connection open for upgrade |
| `proxy_read_timeout 86400s` | 24-hour timeout for idle connections |
| `proxy_buffering off` | Disable buffering for real-time output |
| `keepalive 32` | Connection pool to backend |

### Testing Nginx Configuration

```bash
# Test configuration syntax
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Check WebSocket connection
websocat wss://factory.example.com/
```

## Caddy Configuration

Caddy provides automatic HTTPS with Let's Encrypt and simpler configuration.

### Basic Caddyfile

```caddyfile
# /etc/caddy/Caddyfile

factory.example.com {
    # Automatic TLS via Let's Encrypt

    reverse_proxy localhost:8765 {
        # WebSocket support is automatic in Caddy

        # Pass client IP headers
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}

        # Flush immediately for real-time output
        flush_interval -1

        # Long timeout for WebSocket connections
        transport http {
            read_timeout 24h
            write_timeout 24h
            keepalive 30s
            keepalive_idle_conns 10
        }
    }
}
```

### Caddy with Multiple Factory Instances

```caddyfile
# Load balancing multiple factory servers

factory.example.com {
    reverse_proxy localhost:8765 localhost:8766 localhost:8767 {
        lb_policy round_robin

        # Health checks
        health_uri /health
        health_interval 10s
        health_timeout 5s

        # Sticky sessions for WebSocket
        lb_try_duration 5s

        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}

        flush_interval -1

        transport http {
            read_timeout 24h
            write_timeout 24h
        }
    }
}
```

### Testing Caddy Configuration

```bash
# Validate configuration
caddy validate --config /etc/caddy/Caddyfile

# Reload configuration
sudo systemctl reload caddy

# Check certificate status
caddy trust
```

## X-Forwarded-For Handling

The Factory Server reads client IP from the `X-Forwarded-For` header when running behind a proxy.

### Server Configuration

Set the trusted proxy in your factory configuration:

```yaml
# .cas/config.yaml
factory:
  server:
    # Trust proxy headers from these IPs
    trusted_proxies:
      - 127.0.0.1
      - 10.0.0.0/8
      - 172.16.0.0/12
      - 192.168.0.0/16
```

### Security Considerations

1. **Only trust known proxy IPs** - Prevent IP spoofing by limiting trusted sources
2. **Use X-Real-IP as primary** - More reliable than X-Forwarded-For chain
3. **Log both IPs** - For debugging, log proxy IP and forwarded IP

## Connection Timeout Tuning

WebSocket connections for terminal sessions can be long-lived. Configure timeouts appropriately:

### Recommended Timeouts

| Component | Timeout | Purpose |
|-----------|---------|---------|
| Proxy read | 24 hours | Allow idle terminal sessions |
| Proxy send | 24 hours | Match read timeout |
| Keepalive | 30 seconds | Detect dead connections |
| Protocol ping | 10 seconds | Application-level health check |

### Handling Idle Connections

The Factory protocol includes ping/pong for connection health:

1. Server sends `Ping` every 10 seconds
2. Client responds with `Pong`
3. Server tracks RTT and connection quality
4. Connections with 3+ missed pongs are closed

This application-level keepalive works independently of proxy timeouts.

## Troubleshooting

### WebSocket Upgrade Fails

```
Error: 426 Upgrade Required
```

**Fix:** Ensure `proxy_http_version 1.1` and `Upgrade` headers are set.

### Connection Drops After 60 Seconds

**Cause:** Default proxy timeout is too short.

**Fix:** Increase `proxy_read_timeout` to 24 hours or more.

### Client IP Shows Proxy Address

**Cause:** X-Forwarded-For not being passed or trusted.

**Fix:**
1. Add `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for`
2. Configure `trusted_proxies` in factory config

### High Latency on Terminal Output

**Cause:** Proxy buffering enabled.

**Fix:** Set `proxy_buffering off` (nginx) or `flush_interval -1` (Caddy).

## Example: Full Production Setup

### Directory Structure

```
/etc/nginx/
├── nginx.conf
├── sites-available/
│   └── cas-factory
└── sites-enabled/
    └── cas-factory -> ../sites-available/cas-factory

/etc/systemd/system/
└── cas-factory.service
```

### Systemd Service

```ini
# /etc/systemd/system/cas-factory.service
[Unit]
Description=CAS Factory Server
After=network.target

[Service]
Type=simple
User=cas
Group=cas
WorkingDirectory=/opt/cas
ExecStart=/opt/cas/bin/cas factory serve --host 127.0.0.1 --port 8765
Restart=always
RestartSec=5

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/cas/data

[Install]
WantedBy=multi-user.target
```

### Firewall Rules

```bash
# Allow HTTPS only (proxy handles TLS)
sudo ufw allow 443/tcp

# Block direct access to factory port
sudo ufw deny 8765/tcp
```
