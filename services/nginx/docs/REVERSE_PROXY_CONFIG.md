# Reverse Proxy Configuration for Canary

Your Open WebUI Canary is now running on **localhost:8081** and is accessible via HTTP.

To make it accessible via HTTPS at `https://webui-m4-canary.yourdomain.com`, you need to configure your external reverse proxy.

## 🎯 Current Status
- ✅ **Canary Running**: `http://localhost:8081`
- ✅ **Health Check**: `http://localhost:8081/health` returns 200
- ❌ **HTTPS Access**: Needs reverse proxy configuration

## 🔧 Reverse Proxy Configuration

### For Nginx Proxy Manager
Add a new proxy host:
- **Domain Names**: `webui-m4-canary.yourdomain.com`
- **Scheme**: `http`
- **Forward Hostname/IP**: `YOUR_SERVER_IP` (or `localhost` if on same machine)
- **Forward Port**: `8081`
- **SSL**: Enable with Let's Encrypt or existing wildcard certificate

### For Traefik
Add labels to your canary service or create a dynamic configuration:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.webui-canary.rule=Host(`webui-m4-canary.yourdomain.com`)"
  - "traefik.http.routers.webui-canary.tls=true"
  - "traefik.http.services.webui-canary.loadbalancer.server.port=8081"
```

### For Caddy
Add to your Caddyfile:
```
webui-m4-canary.yourdomain.com {
    reverse_proxy localhost:8081
}
```

### For pfSense/OPNsense HAProxy
- **Backend**: Create new backend pointing to `YOUR_SERVER_IP:8081`
- **Frontend**: Add condition for `webui-m4-canary.yourdomain.com`
- **SSL**: Use existing wildcard certificate or create new one

### For Router-based Reverse Proxy
If using router firmware like OpenWrt with nginx:
```nginx
server {
    listen 443 ssl http2;
    server_name webui-m4-canary.yourdomain.com;
    
    ssl_certificate /path/to/your/cert.pem;
    ssl_certificate_key /path/to/your/key.pem;
    
    location / {
        proxy_pass http://YOUR_SERVER_IP:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 🧪 Testing

### 1. Local Testing (HTTP)
```bash
curl http://localhost:8081/health
# Should return: {"status":"ok"}
```

### 2. Network Testing
```bash
curl http://YOUR_SERVER_IP:8081/health
# Should return: {"status":"ok"}
```

### 3. HTTPS Testing (after proxy config)
```bash
curl https://webui-m4-canary.yourdomain.com/health
# Should return: {"status":"ok"}
```

## 📋 Next Steps

1. **Identify your reverse proxy setup**
2. **Add canary configuration** using the appropriate method above
3. **Test HTTPS access** to `https://webui-m4-canary.yourdomain.com`
4. **Verify canary functionality** (login, OpenRouter, etc.)

## 🔍 Troubleshooting

### If canary shows 500 errors:
```bash
# Check canary logs
cd /path/to/carian-observatory
./manage-canary.sh logs

# Check canary health
./manage-canary.sh health
```

### If DNS doesn't resolve:
- Add to `/etc/hosts`: `YOUR_SERVER_IP webui-m4-canary.yourdomain.com`
- Or configure DNS to point to your reverse proxy

### If SSL certificate errors:
- Use existing wildcard certificate for `*.yourdomain.com`
- Or generate new certificate for `webui-m4-canary.yourdomain.com`

## 🎯 Expected Result

Once configured, you should be able to:
- Access canary at `https://webui-m4-canary.yourdomain.com`
- See "Open WebUI Canary" in the interface
- Test new versions safely without affecting production
- Monitor automatic updates via Watchtower

The canary will automatically update to the latest Open WebUI version daily at 2 AM.
