# Carian Observatory

A self-hosted AI infrastructure platform with modular architecture, authenticated access control, and comprehensive observability. 

<img width="1000" height="563" alt="Caria" src="https://static.wikia.nocookie.net/eldenring/images/6/64/Caria_Manor_2.png/revision/latest?cb=20230410051038" />

_Naming scheme inspired by Elden Ring ([Image Source](https://eldenring.fandom.com/wiki/Caria_Manor?file=Caria_Manor_2.png))_


## Overview

Carian Observatory is a Docker-based platform that integrates multiple AI services behind a unified authentication layer. It provides:

- **AI Chat Interface** via Open-WebUI with support for multiple LLM providers
- **AI-Powered Search** through Perplexica with SearXNG integration
- **Centralized Authentication** using Authelia with WebAuthn/FIDO2 support
- **Platform Monitoring** with Homepage dashboard and Glance feeds
- **Full Observability** via PGLA stack (Prometheus, Grafana, Loki, Alertmanager)
- **Secure Secret Management** through 1Password Connect API
- **Smart Update Strategy** using dual watchtower configuration (production + canary)

All services communicate over private Docker networks with SSL/TLS termination at the nginx reverse proxy layer. Configuration templates ensure no secrets are committed to version control.

<details>
<summary><strong>🏗️ Architecture</strong></summary>

## System Architecture

Carian Observatory uses a modular service architecture with Docker Compose's `include` feature, allowing independent service management while maintaining integration.

### Service Groups

```
📡 Carian Observatory Platform
│
├── 🔐 Authentication Layer
│   ├── co-authelia-service     (WebAuthn/FIDO2, TOTP)
│   └── co-authelia-redis       (Session storage)
│
├── 🌐 AI Services
│   ├── co-open-webui-service   (Production AI chat)
│   ├── co-open-webui-canary    (Canary testing)
│   ├── co-perplexica-service   (AI search)
│   └── co-perplexica-searxng   (Meta-search engine)
│
├── 📊 Platform Services
│   ├── co-homepage-service     (Unified dashboard)
│   ├── co-homepage-iframe-proxy (Secure iframe integration)
│   └── co-glance-service       (RSS monitoring dashboard)
│
├── 📈 Observability Stack (PGLA)
│   ├── co-monitoring-prometheus    (Metrics collection)
│   ├── co-monitoring-grafana       (Visualization)
│   ├── co-monitoring-loki          (Log aggregation)
│   ├── co-monitoring-alertmanager  (Alert routing)
│   ├── co-monitoring-promtail      (Log shipping)
│   ├── co-monitoring-cadvisor      (Container metrics)
│   ├── co-monitoring-node          (System metrics)
│   └── co-monitoring-redis         (Redis metrics)
│
├── 🔒 Infrastructure
│   ├── co-nginx-service        (Reverse proxy + SSL/TLS)
│   ├── co-1p-connect-sync      (1Password vault sync)
│   └── co-1p-connect-api       (Secret retrieval API)
│
└── 🔄 Update Management
    ├── co-ow-watchtower-service (Weekly production updates)
    └── co-ow-watchtower-canary  (Daily canary updates)
```

### Security Model

**Authentication Flow:**
1. User requests service (e.g., `https://webui.yourdomain.com`)
2. Nginx forwards auth check to Authelia
3. If unauthenticated, redirect to `https://auth.yourdomain.com`
4. User authenticates with WebAuthn/FIDO2 or TOTP
5. Session stored in Redis, forwarded to requested service

**Secret Management:**
- Configuration templates use `yourdomain.com` placeholders (safe for git)
- Real domains configured in `.env` (gitignored)
- API keys retrieved from 1Password Connect API
- No secrets in version control or container definitions

### Network Topology

- `carian-observatory_app-network` - Main service communication
- `carian-observatory_onepassword-internal` - Isolated 1Password sync
- All external access through nginx on ports 80/443
- Service-to-service communication on internal Docker networks

### Data Persistence

- **Open-WebUI**: External volume `open-webui-fw_open-webui` (preserved across updates)
- **Authelia**: SQLite database in `services/authelia/data/`
- **Monitoring**: Separate volumes for Prometheus, Grafana, Loki data
- **1Password**: Encrypted cache in `onepassword-data` volume

</details>

<details>
<summary><strong>📦 Services</strong></summary>

## Service Directory

| Service | Purpose | Access | Documentation |
|---------|---------|--------|---------------|
| **Open-WebUI** | AI chat interface with multi-LLM support | `https://webui.yourdomain.com` | [Open-WebUI Docs](https://docs.openwebui.com) |
| **Perplexica** | AI-powered search engine | `https://perplexica.yourdomain.com` | [Perplexica GitHub](https://github.com/ItzCrazyKns/Perplexica) |
| **Authelia** | Authentication portal with MFA | `https://auth.yourdomain.com` | [services/authelia/README.md](services/authelia/README.md) |
| **Homepage** | Unified platform dashboard | `https://homepage.yourdomain.com` | [services/homepage/README.md](services/homepage/README.md) |
| **Glance** | RSS feed monitoring dashboard | `https://glance.yourdomain.com` | [Glance GitHub](https://github.com/glanceapp/glance) |
| **Grafana** | Metrics and logs visualization | `https://monitoring.yourdomain.com` | [services/monitoring/README.md](services/monitoring/README.md) |
| **1Password Connect** | Secure secret management API | `http://localhost:8090` | [services/onepassword/README.md](services/onepassword/README.md) |

### Service States

**Currently Active:**
- ✅ Open-WebUI (production + canary)
- ✅ Perplexica + SearXNG
- ✅ Authelia + Redis
- ✅ Homepage + Glance
- ✅ PGLA monitoring stack
- ✅ Nginx reverse proxy
- ✅ Watchtower (production + canary)

**In Development:**
- 🚧 PostgreSQL (memory storage backend)
- 🚧 1Password Connect (currently using CLI injection)

### Modular Configuration

Services use Docker Compose's `include` feature for modularity:

```yaml
# docker-compose.yml
include:
  - path: services/open-webui/docker-compose.yml
  - path: services/perplexica/docker-compose.yml
  - path: services/authelia/docker-compose.yml
  - path: services/nginx/docker-compose.yml
  - path: services/homepage/docker-compose.yml
  - path: services/glance/docker-compose.yml
  - path: services/monitoring/docker-compose.yml
  # - path: services/onepassword/docker-compose.yml  # Optional
```

To disable a service, comment out its include line and restart: `docker compose up -d`

</details>

<details>
<summary><strong>🚀 Quick Start</strong></summary>

## Quick Start

### Prerequisites

- **Docker Desktop** (macOS/Windows) or **Docker Engine** (Linux)
- **Docker Compose** v2.20+ (for `include` feature support)
- **1Password CLI** (optional, for secret management)
- Available ports: 80, 443, 8080-8093, 9090-9100

**Platform Note**: Designed for macOS. Linux and Windows may require minor adjustments.

### Installation

1. **Generate configuration files from templates:**
   ```bash
   ./create-all-from-templates.sh
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   vim .env
   ```

   Key variables to set:
   - `PRIMARY_DOMAIN` - Your domain (e.g., `example.com`)
   - `AUTHELIA_SESSION_SECRET` - Generate with `openssl rand -hex 32`
   - `AUTHELIA_STORAGE_ENCRYPTION_KEY` - Generate with `openssl rand -hex 32`
   - `GRAFANA_PASSWORD` - Secure admin password

3. **Deploy SSL certificates:**

   Place certificates in `services/nginx/ssl/`:
   ```bash
   webui.yourdomain.com.crt + .key
   perplexica.yourdomain.com.crt + .key
   auth.yourdomain.com.crt + .key
   homepage.yourdomain.com.crt + .key
   glance.yourdomain.com.crt + .key
   monitoring.yourdomain.com.crt + .key
   ```

   Or generate self-signed:
   ```bash
   openssl req -x509 -newkey rsa:2048 -keyout domain.key -out domain.crt -days 365 -nodes
   ```

4. **Start the platform:**
   ```bash
   docker compose up -d
   ```

5. **Verify deployment:**
   ```bash
   docker compose ps
   ```

### First-Time Setup

**Configure Authelia:**
1. Navigate to `https://auth.yourdomain.com`
2. Register first user (becomes admin)
3. Set up WebAuthn/FIDO2 or TOTP 2FA

**Access Services:**
- Open-WebUI: `https://webui.yourdomain.com`
- Perplexica: `https://perplexica.yourdomain.com`
- Homepage: `https://homepage.yourdomain.com`
- Grafana: `https://monitoring.yourdomain.com`

All services require authentication via Authelia.

### Optional: 1Password Integration

For automated API key management:

```bash
# Start 1Password Connect Server
cd services/onepassword
./scripts/manage-connect-server.sh start

# Deploy API keys from 1Password vault
./scripts/deploy-api-keys.sh
```

See [services/onepassword/README.md](services/onepassword/README.md) for detailed setup.

</details>

<details>
<summary><strong>🔐 Security Model</strong></summary>

## Security Architecture

### Template-Based Configuration

Carian Observatory uses a template system to prevent secrets from entering version control:

**Structure:**
```
carian-observatory/
├── templates/                    # Safe for git
│   ├── .env.template
│   └── services/
│       └── {service}/
│           ├── configs/*.template
│           └── scripts/*.template
├── services/                     # Gitignored
│   └── {service}/
│       ├── configs/*.yaml        # Real domains
│       └── scripts/*.sh          # Real domains
└── create-all-from-templates.sh  # Generator script
```

**Process:**
1. Templates use `yourdomain.com` placeholders
2. `create-all-from-templates.sh` generates working files with real domains
3. Generated files are automatically gitignored
4. Only templates are committed to version control

### Secret Management

**1Password Connect API:**
- Sync container maintains encrypted vault cache
- API container provides REST access to secrets
- CLI injection for runtime secret deployment
- No secrets stored in containers or environment files

**Environment Variables:**
- Critical secrets in `.env` (gitignored)
- Templates use `${VARIABLE}` substitution
- API keys retrieved from 1Password vault

### Authentication Layer

**Authelia Configuration:**
- Default policy: `deny` (explicit allow required)
- All services require authentication
- WebAuthn/FIDO2 support for hardware keys
- TOTP for software-based 2FA
- Session persistence in Redis

**Access Control:**
```yaml
# services/authelia/configs/configuration.yml
access_control:
  default_policy: 'deny'
  rules:
    - domain: 'webui.yourdomain.com'
      policy: 'two_factor'
    - domain: 'perplexica.yourdomain.com'
      policy: 'two_factor'
```

**Important**: When adding services, update Authelia access control or requests will return 403 Forbidden.

### SSL/TLS Implementation

- All external traffic terminates SSL at nginx
- Service-to-service communication over internal Docker networks
- Certificates managed in `services/nginx/ssl/`
- Automatic HTTP to HTTPS redirects

### Network Isolation

- Services communicate on `carian-observatory_app-network`
- 1Password sync isolated on `onepassword-internal` network
- No direct external access to services (nginx proxy only)
- Container-to-container communication via Docker DNS

</details>

<details>
<summary><strong>🛠️ Operations</strong></summary>

## Daily Operations

### Common Commands

| Task | Command | Description |
|------|---------|-------------|
| **Start All Services** | `docker compose up -d` | Starts platform |
| **Stop All Services** | `docker compose down` | Stops platform |
| **View Status** | `docker compose ps` | Shows service health |
| **View Logs** | `docker compose logs -f [service]` | Follow service logs |
| **Restart Service** | `docker restart [container-name]` | Restart specific container |

### Service Group Management

**Authentication Stack:**
```bash
docker logs co-authelia-service co-authelia-redis
docker restart co-authelia-service co-authelia-redis
```

**Web Interface Stack:**
```bash
docker logs co-open-webui-service co-open-webui-canary
docker restart co-open-webui-service
```

**AI Search Stack:**
```bash
docker logs co-perplexica-service co-perplexica-searxng
docker restart co-perplexica-service co-perplexica-searxng
```

**Monitoring Stack:**
```bash
docker logs co-monitoring-prometheus co-monitoring-grafana
docker logs co-monitoring-loki co-monitoring-alertmanager
docker restart co-monitoring-prometheus co-monitoring-grafana
```

### Troubleshooting

**403 Forbidden Errors:**
- Check Authelia access control rules in `services/authelia/configs/configuration.yml`
- Ensure service domain is explicitly allowed
- Verify nginx configuration includes service

**Service Won't Start:**
```bash
docker compose logs [service-name]
docker inspect [container-name]
```

**Authentication Issues:**
```bash
docker logs co-authelia-service
docker logs co-authelia-redis
docker exec co-authelia-service cat /config/configuration.yml
```

**SSL Certificate Problems:**
```bash
docker exec co-nginx-service nginx -t
ls -la services/nginx/ssl/
docker restart co-nginx-service
```

**Network Connectivity:**
```bash
docker network inspect carian-observatory_app-network
docker exec co-nginx-service ping co-authelia-service
```

### Updating Services

**Production Services:**
- Updated weekly via `co-ow-watchtower-service`
- Monitors: open-webui, perplexica, authelia, nginx

**Canary Services:**
- Updated daily via `co-ow-watchtower-canary`
- Monitors: open-webui-canary

**Manual Updates:**
```bash
docker compose pull
docker compose up -d
```

### Data Backup

**Critical Data Locations:**
- Open-WebUI: `open-webui-fw_open-webui` volume
- Authelia: `services/authelia/data/`
- Monitoring: `co-prometheus-data`, `co-grafana-data`, `co-loki-data` volumes

**Backup Command:**
```bash
docker run --rm -v open-webui-fw_open-webui:/data -v $(pwd):/backup alpine tar czf /backup/openwebui-backup.tar.gz /data
```

### Detailed Operations

See subdirectory READMEs for detailed operational guides:
- [Authentication Scripts](scripts/authentication/README.md)
- [Infrastructure Scripts](scripts/infrastructure/README.md)
- [1Password Scripts](scripts/onepassword/README.md)

</details>

<details>
<summary><strong>🔧 Development</strong></summary>

## Development Workflow

### Adding New Services

1. **Create service directory:**
   ```bash
   mkdir -p services/newservice/{configs,scripts}
   ```

2. **Create docker-compose.yml:**
   ```yaml
   # services/newservice/docker-compose.yml
   services:
     newservice:
       image: your/image:tag
       container_name: co-newservice-service
       restart: unless-stopped
       networks:
         - app-network

   networks:
     app-network:
       name: ${COMPOSE_PROJECT_NAME}_app-network
   ```

3. **Add to master docker-compose.yml:**
   ```yaml
   include:
     - path: services/newservice/docker-compose.yml
   ```

4. **Configure nginx routing:**
   ```bash
   vim services/nginx/configs/https.conf.template
   ```

   Add server block for new service.

5. **Update Authelia access control:**
   ```yaml
   # services/authelia/configs/configuration.yml
   access_control:
     rules:
       - domain: 'newservice.yourdomain.com'
         policy: 'two_factor'
   ```

6. **Update environment variables:**
   ```bash
   vim .env.example
   ```

7. **Restart services:**
   ```bash
   docker restart co-authelia-service co-nginx-service
   docker compose up -d
   ```

### Testing Strategy

**Canary Testing:**
- Canary services receive daily updates
- Test new versions before production deployment
- Production services receive weekly updates after validation

**Service Verification:**
```bash
# Check service health
docker compose ps

# Test authentication flow
curl -I https://newservice.yourdomain.com

# Verify nginx configuration
docker exec co-nginx-service nginx -t
```

### Configuration Templates

**Creating Templates:**
1. Write configuration with `yourdomain.com` placeholders
2. Save as `.template` file in `templates/services/{service}/`
3. Add generation logic to `create-all-from-templates.sh`
4. Generate working files: `./create-all-from-templates.sh`

**Template Variables:**
- `yourdomain.com` → Replaced with `${PRIMARY_DOMAIN}`
- `${VARIABLE}` → Replaced with environment variable value

</details>

---

## Project Structure

```
carian-observatory/
├── docker-compose.yml              # Master service orchestration
├── .env.example                    # Environment configuration template
├── create-all-from-templates.sh    # Configuration generator
├── services/                       # Modular service definitions
│   ├── authelia/                   # Authentication service
│   ├── open-webui/                 # AI chat interface
│   ├── perplexica/                 # AI search engine
│   ├── homepage/                   # Platform dashboard
│   ├── glance/                     # Monitoring dashboard
│   ├── monitoring/                 # PGLA observability stack
│   ├── nginx/                      # Reverse proxy + SSL
│   └── onepassword/                # Secret management
├── templates/                      # Configuration templates (git-safe)
└── scripts/                        # Operational scripts
    ├── authentication/             # Auth management scripts
    ├── infrastructure/             # Platform management scripts
    └── onepassword/                # Secret deployment scripts
```

## Design Principles

### What This Project Prioritizes

**Security by Default:**
- Multi-factor authentication required for all services
- Template-based configuration preventing secret exposure
- 1Password integration for centralized secret management
- SSL/TLS encryption for all external traffic
- Default-deny access control policies

**Operational Excellence:**
- Modular architecture for independent service management
- Comprehensive observability (metrics, logs, alerts)
- Automated updates with canary testing
- Clear separation between production and testing environments

**Maintainability:**
- Infrastructure as code with version control
- Self-documenting configuration templates
- Standardized container naming conventions
- Detailed operational documentation

### What This Project Avoids

**Anti-Patterns Explicitly Rejected:**
- ❌ Hardcoded secrets in configuration files or code
- ❌ Services without authentication requirements
- ❌ Single-factor authentication
- ❌ Secrets committed to version control
- ❌ Unencrypted service communication
- ❌ Missing observability and monitoring
- ❌ Manual update processes without testing
- ❌ Monolithic architectures preventing independent scaling

**Security Standards:**
- No API keys in environment files committed to git
- No default passwords or weak authentication
- No unauthenticated service endpoints
- No plain HTTP for external traffic
- No shared credentials across services

This platform demonstrates security-conscious infrastructure design with practical implementations of modern DevOps practices.
