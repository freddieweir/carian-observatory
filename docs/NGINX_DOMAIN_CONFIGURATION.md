# Nginx Domain Configuration Guide

## Overview
Your nginx configuration has been successfully converted from hardcoded domains to environment variables. This makes it easy to change domains without modifying nginx configuration files directly.

## Configuration Files

### Domain Variables (.env)
The main domain configuration is now stored in your `.env` file:

```bash
# Primary domain for your services
PRIMARY_DOMAIN=yourdomain.com

# Machine identifier for multi-machine setups
MACHINE_ID=m4

# Service subdomains
WEBUI_SUBDOMAIN=webui
PERPLEXICA_SUBDOMAIN=perplexica
SEARXNG_SUBDOMAIN=search
AUTH_SUBDOMAIN=auth
CANARY_SUBDOMAIN=webui-canary

# Constructed domain names (used by nginx configuration)
WEBUI_DOMAIN=${WEBUI_SUBDOMAIN}-${MACHINE_ID}.${PRIMARY_DOMAIN}
PERPLEXICA_DOMAIN=${PERPLEXICA_SUBDOMAIN}-${MACHINE_ID}.${PRIMARY_DOMAIN}
AUTH_DOMAIN=${AUTH_SUBDOMAIN}-${MACHINE_ID}.${PRIMARY_DOMAIN}
CANARY_DOMAIN=${CANARY_SUBDOMAIN}.${PRIMARY_DOMAIN}

# Generic domains for fallback/examples
GENERIC_WEBUI_DOMAIN=webui.yourdomain.com
GENERIC_PERPLEXICA_DOMAIN=perplexica.yourdomain.com
GENERIC_AUTH_DOMAIN=auth-m4.yourdomain.com
```

### Nginx Template (`services/nginx/configs/https.conf.template`)
The nginx configuration is now a template that uses environment variables like `${WEBUI_DOMAIN}`, `${CANARY_DOMAIN}`, etc.

## Current Domain Mapping
Based on your current configuration:

- **WebUI Production**: webui-m4.yourdomain.com
- **WebUI Canary**: webui-canary.yourdomain.com  
- **Perplexica**: perplexica-m4.yourdomain.com
- **Authelia**: auth-m4.yourdomain.com

## How to Change Domains

### Option 1: Quick Domain Change
To change just the primary domain:

1. Edit `.env` file:
   ```bash
   PRIMARY_DOMAIN=yournewdomain.com
   ```

2. Run the update script:
   ```bash
   ./scripts/update-nginx-domains.sh
   ```

### Option 2: Full Customization
To fully customize domains:

1. Edit the domain variables in `.env`:
   ```bash
   PRIMARY_DOMAIN=yournewdomain.com
   MACHINE_ID=server1
   WEBUI_SUBDOMAIN=app
   # etc...
   ```

2. Run the update script:
   ```bash
   ./scripts/update-nginx-domains.sh
   ```

### Option 3: Manual Docker Restart
If you prefer to restart services manually:

```bash
# After editing .env
docker compose restart nginx
```

## Update Script Features

The `scripts/update-nginx-domains.sh` script provides:

- ✅ Environment variable validation
- 🌐 Domain mapping preview
- 🔄 Automatic nginx container restart
- ✅ Health check validation
- 🎨 Colorized output for easy reading

## SSL Certificates

Remember to update your SSL certificates when changing domains:

```bash
# Your certificates should match the new domains
/etc/ssl/custom/webui-m4.yournewdomain.com.crt
/etc/ssl/custom/webui-canary.yournewdomain.com.crt
# etc...
```

## Troubleshooting

### Container Won't Start
```bash
# Check nginx logs
docker logs co-nginx-service

# Validate configuration syntax
docker exec co-nginx-service nginx -t
```

### Missing Environment Variables
The script will tell you if required variables are missing from `.env`.

### SSL Certificate Issues
Ensure certificate files exist and match your domain names in the ssl volume mount.

## Technical Details

- Uses nginx:alpine's built-in template processing
- Environment variable substitution happens at container startup
- Nginx variables (`$host`, `$remote_addr`, etc.) are preserved
- Template file: `/etc/nginx/templates/default.conf.template`
- Generated config: `/etc/nginx/conf.d/default.conf`

## Security Notes

- Template processing only substitutes defined environment variables
- Nginx's internal variables are protected from substitution
- Configuration is regenerated on every container restart
- SSL/TLS settings remain unchanged from the original secure configuration