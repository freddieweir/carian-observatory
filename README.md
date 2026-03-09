# Carian Observatory

Infrastructure watchtower for the Carian ecosystem. Reverse proxy, monitoring, auto-updates, and secret management for all three stacks.

Part of [Carian Stacks](https://github.com/freddieweir/carian-stacks) |
**Observatory** · [Library](https://github.com/freddieweir/carian-library) · [Manor](https://github.com/freddieweir/carian-manor)

## What Observatory Does

| Capability | How |
|------------|-----|
| Reverse proxy + SSL | Nginx terminates TLS, routes to all three stacks |
| Monitoring | PGLA — Prometheus, Grafana, Loki, Alertmanager |
| Container metrics | cAdvisor + Node Exporter feed Prometheus |
| Auto-updates | Dual watchtower — daily production, hourly canary |
| Secret management | 1Password Connect API on isolated network |
| Shared networking | Creates `carian-shared` bridge for Manor and Library |

> Deploy Observatory **first** — it creates the network other stacks join.

## Services

### Core

| Container | Image | Role |
|-----------|-------|------|
| `co-nginx-service` | `nginx:alpine` | Reverse proxy, SSL termination |
| `co-watchtower-service` | `containrrr/watchtower` | Daily auto-updates (production) |
| `co-watchtower-canary` | `containrrr/watchtower` | Hourly auto-updates (canary) |

### PGLA Monitoring Stack

| Container | Image | Role |
|-----------|-------|------|
| `co-monitoring-prometheus` | `prom/prometheus` | Metrics collection and storage |
| `co-monitoring-grafana` | `grafana/grafana` | Dashboards and visualization |
| `co-monitoring-cadvisor` | `gcr.io/cadvisor/cadvisor` | Container resource metrics |
| `co-monitoring-node` | `prom/node-exporter` | Host system metrics |
| `co-monitoring-redis` | `oliver006/redis_exporter` | Redis metrics (Authelia sessions) |
| `co-monitoring-loki` | `grafana/loki` | Log aggregation |
| `co-monitoring-promtail` | `grafana/promtail` | Log shipping to Loki |
| `co-monitoring-alerts` | `prom/alertmanager` | Alert routing and notification |

### 1Password Connect (separate deployment)

| Container | Image | Role |
|-----------|-------|------|
| `co-1p-connect-sync` | `1password/connect-sync` | Syncs vault with 1Password.com |
| `co-1p-connect-api` | `1password/connect-api` | REST API for secret retrieval |

## Cross-Stack Watchtower

Observatory's watchtowers manage containers across all three stacks:

| Watchtower | Interval | Containers Watched |
|------------|----------|-------------------|
| `co-watchtower-service` | Daily (24h) | `cm-open-webui-service`, `cl-perplexica-service`, `cl-perplexica-searxng`, `cm-authelia-service`, `cm-authelia-redis`, `co-nginx-service` |
| `co-watchtower-canary` | Hourly | `cl-open-webui-canary` |

## Quick Start

### Prerequisites

- Docker Compose v2.20+ (for `include` support)
- 1Password CLI (`op`) for secret injection
- Ports: 80, 443, 3000, 3100, 8080, 9090, 9093, 9100, 9121

### Deploy

```bash
# 1. Configure environment
cp .env.example .env && vim .env

# 2. Inject secrets from 1Password
op inject -f -i .env -o .env.resolved

# 3. Start Observatory (creates carian-shared network)
docker compose --env-file .env.resolved up -d

# 4. Verify
docker compose ps
```

### Template System

Configuration uses `yourdomain.com` placeholders — real domains stay in `.env` (gitignored). Run `./create-all-from-templates.sh` to generate working configs from templates.

## Further Reading

| Doc | Contents |
|-----|----------|
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | Service management, troubleshooting, backup |
| [docs/SECURITY.md](docs/SECURITY.md) | Template system, 1Password, network isolation |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Adding services, testing, configuration |
| [docs/MONITORING-TLDR.md](docs/MONITORING-TLDR.md) | PGLA stack quick reference |

---

<sub>Named after the [Carian Study Hall](https://eldenring.wiki.fextralife.com/Carian+Study+Hall) from Elden Ring — the astronomers who studied the stars from their towers, watching over the realm below.</sub>
