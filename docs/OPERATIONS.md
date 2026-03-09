# Operations Guide

## Common Commands

| Task | Command |
|------|---------|
| Start all services | `docker compose --env-file .env.resolved up -d` |
| Stop all services | `docker compose down` |
| View status | `docker compose ps` |
| Follow logs | `docker compose logs -f [service]` |
| Restart service | `docker restart [container-name]` |

## Service Group Management

### Monitoring Stack

```bash
docker logs co-monitoring-prometheus co-monitoring-grafana
docker logs co-monitoring-loki co-monitoring-alerts
docker restart co-monitoring-prometheus co-monitoring-grafana
```

### Reverse Proxy

```bash
docker logs co-nginx-service
docker exec co-nginx-service nginx -t   # Test config
docker restart co-nginx-service
```

### 1Password Connect

```bash
docker logs co-1p-connect-sync co-1p-connect-api
docker restart co-1p-connect-sync co-1p-connect-api
```

## Troubleshooting

### 403 Forbidden Errors

Check Authelia access control in Manor's `services/authelia/configs/configuration.yml`. Every service domain needs an explicit allow rule.

### SSL Certificate Problems

```bash
docker exec co-nginx-service nginx -t        # Validate config
ls -la services/nginx/ssl/                    # Check certs exist
docker restart co-nginx-service               # Apply changes
```

### Network Connectivity

```bash
docker network inspect carian-shared
docker exec co-nginx-service ping cm-authelia-service
```

### Service Won't Start

```bash
docker compose logs [service-name]
docker inspect [container-name]
```

## Auto-Updates

| Watchtower | Scope | Interval | Watched Containers |
|------------|-------|----------|-------------------|
| `co-watchtower-service` | Production | Daily (24h) | cm-open-webui, cl-perplexica, cm-authelia, co-nginx |
| `co-watchtower-canary` | Canary | Hourly | cl-open-webui-canary |

### Manual Updates

```bash
docker compose pull
docker compose --env-file .env.resolved up -d
```

## Data Backup

### Critical Data Locations

| Volume | Contents |
|--------|----------|
| `co-prometheus-data` | Metrics (30 day retention) |
| `co-grafana-data` | Dashboards and settings |
| `co-loki-data` | Aggregated logs |

### Backup Command

```bash
docker run --rm -v co-grafana-data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz /data
```
