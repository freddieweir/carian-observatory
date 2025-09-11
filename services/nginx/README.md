# Nginx Reverse Proxy Service

This directory contains the nginx reverse proxy configuration for the Athena Core infrastructure.

## Directory Structure

```
services/nginx/
├── README.md                    # This file
├── docker-compose.yml           # Nginx service definition
└── docs/
    └── REVERSE_PROXY_CONFIG.md  # Reverse proxy configuration guide
```

## Quick Reference

### Start Service
```bash
# From project root
docker compose up -d nginx
```

### Reload Configuration
```bash
# From project root
docker compose exec nginx nginx -s reload
```

### Test Configuration
```bash
# From project root
docker compose exec nginx nginx -t
```

## Files

### `docker-compose.yml`
Defines the nginx reverse proxy service with:
- SSL/TLS termination
- Multi-domain routing
- Authentication integration with Authelia
- Health checks and monitoring

### `docs/REVERSE_PROXY_CONFIG.md`
Detailed configuration guide covering:
- Canary deployment routing
- SSL certificate management
- Domain configuration
- Authentication flow integration

## Features

- **SSL/TLS Termination**: Automatic HTTPS handling
- **Multi-Domain Routing**: Route multiple subdomains to services
- **Authentication Integration**: Seamless Authelia integration
- **Load Balancing**: Support for multiple backend instances  
- **Health Checks**: Monitor backend service availability
- **Security Headers**: Modern security header configuration

## Service Routing

The nginx service routes requests to:
- `webui-m4.domain.com` → Open-WebUI service
- `perplexica-m4.domain.com` → Perplexica service  
- `auth-m4.domain.com` → Authelia authentication
- `webui-canary.domain.com` → Open-WebUI canary testing

## SSL/TLS Configuration

SSL certificates are managed via:
- 1Password Connect Server for certificate storage
- Automatic certificate deployment scripts
- Let's Encrypt integration support

For detailed configuration instructions, see [docs/REVERSE_PROXY_CONFIG.md](docs/REVERSE_PROXY_CONFIG.md).