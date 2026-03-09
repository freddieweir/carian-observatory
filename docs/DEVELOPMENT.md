# Development Guide

## Adding New Services

1. **Create service directory:**
   ```bash
   mkdir -p services/newservice/{configs,scripts}
   ```

2. **Create docker-compose.yml:**
   ```yaml
   services:
     newservice:
       image: your/image:tag
       container_name: co-newservice-service
       restart: unless-stopped
       networks:
         - carian-shared

   networks:
     carian-shared:
       external: true
       name: carian-shared
   ```

3. **Add to main docker-compose.yml:**
   ```yaml
   include:
     - path: services/newservice/docker-compose.yml
   ```

4. **Configure nginx routing** in `services/nginx/configs/https.conf.template`

5. **Update Authelia access control** (in Manor's Authelia config):
   ```yaml
   - domain: 'newservice.yourdomain.com'
     policy: 'two_factor'
   ```

6. **Add environment variables** to `.env.example`

7. **Deploy:**
   ```bash
   docker restart cm-authelia-service co-nginx-service
   docker compose --env-file .env.resolved up -d
   ```

## Naming Conventions

| Component | Pattern | Example |
|-----------|---------|---------|
| Container | `co-{service}-{role}` | `co-monitoring-prometheus` |
| Network | `carian-shared` (cross-stack) | Shared bridge |
| Volume | `co-{service}-data` | `co-prometheus-data` |

## Testing

### Canary Strategy

Observatory runs a canary watchtower (`co-watchtower-canary`) that updates Library's `cl-open-webui-canary` hourly. After validation, the production watchtower updates Manor's `cm-open-webui-service` daily.

### Verification

```bash
# Check all services are healthy
docker compose ps

# Test nginx config
docker exec co-nginx-service nginx -t

# Verify monitoring targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'

# Check Grafana dashboards load
curl -s http://localhost:3000/api/health
```

## Configuration Templates

### Creating Templates

1. Write config with `yourdomain.com` placeholders
2. Save as `.template` in `templates/services/{service}/`
3. Add generation logic to `create-all-from-templates.sh`
4. Generate: `./create-all-from-templates.sh`

### Template Variables

| Placeholder | Replaced With |
|-------------|--------------|
| `yourdomain.com` | `${PRIMARY_DOMAIN}` value |
| `${VARIABLE}` | Environment variable value |
