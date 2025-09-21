# Carian Observatory

<img width="1000" height="563" alt="The_Three_sister" src="https://github.com/user-attachments/assets/5debed05-156c-4b42-a5e8-eade5546f593" />


A comprehensive AI infrastructure platform featuring enterprise security, modern authentication, and scalable microservices architecture.

## 📋 Prerequisites

Before deploying Carian Observatory, ensure you have:

### 🔧 Essential Requirements
- **Docker Desktop** (macOS/Windows) or **Docker Engine** (Linux)
- **Docker Compose** v2.20+ (for modular include feature)
- **Git** (for cloning repository)
- **Basic terminal/command line** familiarity

**🍎 Platform Note**: This repository was designed with **macOS usage in mind**. Windows and Linux users may experience variations in certain setup steps (YMMV - Your Mileage May Vary).

### 🔐 Security Management Options

Choose your preferred secret management approach:

#### Option A: **1Password CLI** (Recommended)
- 1Password account with CLI access
- Service Account or personal vault access
- Automatic secret injection and rotation

#### Option B: **Manual Configuration**
- Manual `.env` file management
- Direct API key configuration
- Good for personal deployments

#### Option C: **Alternative Tools**
- Other secret management solutions
- Custom environment variable handling

### 🌐 Network Requirements
- Available ports: 80, 443 (nginx), 8080-8090 (services)
- Domain names or localhost setup
- SSL certificate access (self-signed or CA-issued)

## Quick Start

```bash
# Generate all configuration files from templates
./create-all-from-templates.sh

# Edit .env with your settings (generated from template)
vim .env

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f [service-name]
```

## Services

### Core Services
- **Open-WebUI**: AI chat interface at `https://webui.yourdomain.com`
- **Perplexica**: AI-powered search at `https://perplexica.yourdomain.com`
- **Authelia**: Authentication portal at `https://auth.yourdomain.com`
- **Homepage**: Unified dashboard at `https://homepage.yourdomain.com`
- **Glance**: Monitoring dashboard at `https://glance.yourdomain.com`
- **Grafana**: Observability platform at `https://monitoring.yourdomain.com`
- **Nginx**: Reverse proxy with SSL termination

### Architecture

```
services/
├── nginx/          # Reverse proxy and SSL termination
├── authelia/       # Authentication + Redis
├── open-webui/     # AI chat interface (production + canary)
├── perplexica/     # AI search (includes SearXNG)
├── homepage/       # Unified platform dashboard
├── glance/         # Monitoring dashboard with RSS feeds
├── monitoring/     # PGLA stack (Prometheus + Grafana + Loki + Alertmanager)
└── onepassword/    # 1Password Connect API for secure credential management
```

## Configuration

### Enable/Disable Services
Edit `docker-compose.yml` and comment out unwanted services:
```yaml
include:
  - path: services/open-webui/docker-compose.yml
  # - path: services/monitoring/docker-compose.yml  # Disabled
```

### Canary Testing
Test latest Open-WebUI version without affecting production:
```yaml
include:
  - path: services/open-webui/docker-compose.canary.yml
```
Access at `http://localhost:8081`

## 📝 Template System

Carian Observatory uses a secure template system that separates configuration templates (safe to commit) from generated files with real domains (gitignored for security).

### Structure
```
carian-observatory/
├── templates/              # Safe to commit - generic domains only
│   ├── .env.template       # Environment variables with placeholders
│   ├── services/           # Mirrors actual service structure
│   │   ├── homepage/
│   │   │   ├── configs/    # *.yaml.template files
│   │   │   └── scripts/    # *.sh.template files
│   │   ├── authelia/
│   │   ├── nginx/
│   │   └── [other-services]/
│   └── scripts/
│       └── infrastructure/ # System management script templates
├── services/               # Generated files (gitignored)
│   ├── homepage/
│   │   ├── configs/        # *.yaml files with real domains
│   │   └── scripts/        # *.sh files with real domains
│   └── [other-services]/
└── create-all-from-templates.sh  # Master generation script
```

### Usage

1. **Generate all files from templates:**
   ```bash
   ./create-all-from-templates.sh
   ```

2. **Edit templates (safe to commit):**
   ```bash
   # Edit any .template file in templates/ directory
   vim templates/services/homepage/configs/settings.yaml.template

   # Regenerate working files
   ./create-all-from-templates.sh
   ```

3. **Add new service templates:**
   ```bash
   # Create service template directory
   mkdir -p templates/services/newservice/{configs,scripts}

   # Add templates with yourdomain.com placeholders
   echo "domain: yourdomain.com" > templates/services/newservice/configs/config.yaml.template

   # Update master script to process new templates
   vim create-all-from-templates.sh
   ```

### Security Benefits
- ✅ **Zero domain exposure risk**: Only generic `yourdomain.com` in git history
- ✅ **Automatic gitignore**: Generated files are directory-level excluded
- ✅ **Template versioning**: Safe collaboration on configuration changes
- ✅ **1Password integration**: Handles encrypted environment variables seamlessly

### Template Variables
Templates support two processing modes:
- **Simple substitution**: `yourdomain.com` → your actual domain
- **Environment variables**: `${VARIABLE_NAME}` → value from `.env` file

### Complete Template Coverage

The template system now covers **ALL** scripts and configurations:

#### Script Templates (`templates/scripts/`)
- **Authentication** (6 scripts): Password management, 2FA setup, YubiKey configuration
- **Certificates** (4 scripts): SSL deployment, certificate migration, setup utilities
- **Infrastructure** (2 scripts): Host management, secret-enabled startup
- **Migration** (5 scripts): Portfolio migration, modular conversion, summary tools
- **OnePassword** (6 scripts): Connect API, OTC retrieval, certificate storage
- **Monitoring** (system monitoring scripts)
- **Root-level** (4 scripts): Repository sanitization, Authelia configuration

#### Service Templates (`templates/services/`)
- **Authelia**: Full authentication configuration
- **Nginx**: HTTPS reverse proxy configuration with all service domains
- **Homepage**: Unified dashboard configuration and startup scripts
- **Glance**: Monitoring dashboard configuration
- **Monitoring**: PGLA observability stack configuration

Total: **28 script templates** ensuring zero domain exposure (including infrastructure management)

## SSL Certificates

Place certificates in `services/nginx/ssl/`:
- `webui.yourdomain.com.crt` + `.key`
- `perplexica.yourdomain.com.crt` + `.key`
- `auth.yourdomain.com.crt` + `.key`

**Note**: Simplified domain names are used for local networks (no machine ID suffix).

Generate self-signed certificates:
```bash
openssl req -x509 -newkey rsa:2048 -keyout domain.key -out domain.crt -days 365 -nodes
```

## Environment Variables

Key variables in `.env`:
- `AUTHELIA_SESSION_SECRET` - 32-character hex string
- `AUTHELIA_STORAGE_ENCRYPTION_KEY` - 32-character hex string
- `OPENAI_API_KEY` - OpenAI API access
- `CLAUDE_API_KEY` - Anthropic Claude access

## Maintenance

```bash
# Stop all services
docker compose down

# Update services
docker compose pull
docker compose up -d

# Clean up
docker system prune -a
```

## Troubleshooting

Check service logs:
```bash
docker compose logs nginx
docker compose logs authelia
docker compose logs open-webui
```

Reset Authelia database:
```bash
rm services/auth/data/db.sqlite3
docker compose restart authelia
```

## Production Data

**IMPORTANT**: The Open-WebUI production volume `open-webui-fw_open-webui` contains all user data and must be preserved. It's referenced as an external volume and won't be deleted by Docker Compose operations.

---

# 🚀 TL;DR - Most Common Commands

Quick reference for daily operations. All commands run from `carian-observatory/` directory.

## 📋 Daily Operations

| Task | Command | What it Does |
|------|---------|--------------|
| **🚀 Start Everything** | `./scripts/infrastructure/start-with-secrets.sh` | Starts all services with API keys |
| **💚 Health Check** | `./scripts/infrastructure/health-check.sh` | Full system health check |
| **🔄 Smart Restart** | `./scripts/infrastructure/smart-restart.sh` | Intelligently restarts services |
| **📊 Service Status** | `docker compose ps` | Shows all container status |
| **📝 View Logs** | `docker compose logs -f [service]` | Follow logs for specific service |

## 🔐 Authentication & 1Password

| Task | Command | What it Does |
|------|---------|--------------|
| **🔑 Get OTC (Passkey Setup)** | `python scripts/authentication/get_otc.py` | Extracts OTC for passkey registration |
| **🧹 Get OTC + Auto-cleanup** | `python scripts/authentication/get_otc.py --auto-cleanup 30` | Gets OTC, clears file after 30s |
| **🚀 Start 1Password Server** | `./scripts/onepassword/manage-connect-server.sh start` | Starts 1Password Connect Server |
| **🔑 Deploy API Keys** | `./scripts/onepassword/deploy-api-keys.sh` | Pulls API keys from 1Password |
| **📱 Monitor 2FA Setup** | `./scripts/authentication/monitor-2fa-setup.sh` | Shows TOTP QR codes |

## 🎯 Service Groups (New Structured Architecture)

### 🔐 Authentication Stack
```bash
docker logs co-authelia-service co-authelia-redis     # View auth logs
docker restart co-authelia-service co-authelia-redis  # Restart auth stack
```

### 🌐 Web Interface Stack
```bash
docker logs co-open-webui-service                     # Production logs
docker logs co-open-webui-canary                      # Canary logs
docker restart co-open-webui-service                  # Restart production
docker restart co-open-webui-canary                   # Restart canary
```

### 🔍 AI Search Stack
```bash
docker logs co-perplexica-service co-perplexica-searxng   # Search logs
docker restart co-perplexica-service co-perplexica-searxng # Restart search
```

### 📊 Dashboard Stack
```bash
docker logs co-homepage-service co-homepage-iframe-proxy  # Dashboard logs
docker logs co-glance-service                             # Monitoring dashboard
docker restart co-homepage-service co-glance-service      # Restart dashboards
```

### 📈 Observability Stack (PGLA)
```bash
docker logs co-monitoring-prometheus co-monitoring-grafana   # Core metrics
docker logs co-monitoring-loki co-monitoring-alertmanager   # Logs & alerts
docker restart co-monitoring-prometheus                     # Restart metrics
docker restart co-monitoring-grafana                        # Restart dashboards
```

### 🔄 Update Management
```bash
docker logs co-ow-watchtower-service                  # Weekly production updates
docker logs co-ow-watchtower-canary                   # Daily canary updates
```

## 🛠️ Common Workflows

### **Adding a Passkey to Authelia**
```bash
# 1. Go to https://auth-m4.yourdomain.com → Settings → Security
# 2. Click "Add Passkey", when it says "OTC sent to email":
python scripts/authentication/get_otc.py
# 3. Paste (Cmd+V) the code in browser
```

### **Morning Startup Routine**
```bash
./scripts/infrastructure/health-check.sh              # Check system health
./scripts/infrastructure/start-with-secrets.sh        # Start with API keys
docker compose ps                                     # Verify all running
```

### **Troubleshooting Issues**
```bash
./scripts/infrastructure/health-check.sh              # Diagnose problems
docker compose logs nginx                             # Check proxy logs
./scripts/infrastructure/smart-restart.sh [service]   # Restart problematic service
```

### **1Password Setup (First Time)**
```bash
./scripts/onepassword/manage-connect-server.sh start  # Start Connect Server
./scripts/onepassword/manage-connect-server.sh token create  # Generate token
export CONNECT_TOKEN="your-token"                     # Set token
./scripts/onepassword/deploy-api-keys.sh --validate   # Test connection
```

## 📊 Visual Service Map

```
📡 Carian Observatory Platform
├── 🔐 Authentication
│   ├── co-authelia-service     (port 9091)
│   └── co-authelia-redis       (port 6379)
├── 🌐 Web Interface
│   ├── co-open-webui-service   (prod, port 8080)
│   └── co-open-webui-canary    (test, port 8081)
├── 🔍 AI Search
│   ├── co-perplexica-service   (port 3000)
│   └── co-perplexica-searxng   (port 8080)
├── 📊 Dashboard Integration
│   ├── co-homepage-service     (port 3000)
│   ├── co-homepage-iframe-proxy (port 3001)
│   └── co-glance-service       (port 61208)
├── 📈 Observability (PGLA Stack)
│   ├── co-monitoring-prometheus (port 9090)
│   ├── co-monitoring-grafana   (port 3000)
│   ├── co-monitoring-loki      (port 3100)
│   ├── co-monitoring-alertmanager (port 9093)
│   ├── co-monitoring-cadvisor  (port 8080)
│   └── co-monitoring-node-exporter (port 9100)
├── 🌉 Infrastructure
│   ├── co-nginx-service        (ports 80/443)
│   ├── co-1p-connect-sync      (1Password sync)
│   └── co-1p-connect-api       (port 8090)
└── 🔄 Updates
    ├── co-ow-watchtower-service (weekly)
    └── co-ow-watchtower-canary  (daily)
```

## 🔗 Detailed Script Documentation

- 🔐 [Authentication Scripts](scripts/authentication/README.md) - Passkey, 2FA, OTC tools
- 🏗️ [Infrastructure Scripts](scripts/infrastructure/README.md) - Startup, health, restart tools  
- 🔑 [1Password Scripts](scripts/onepassword/README.md) - Connect Server, API key management

## 💡 Pro Tips

- 🎯 **Use service groups**: Restart related services together (auth stack, web stack, etc.)
- 🧹 **Auto-cleanup OTCs**: Use `--auto-cleanup 30` to clear notification files automatically
- 📊 **Visual health checks**: The health check script shows color-coded status for easy scanning
- 🔄 **Smart restarts**: The smart restart script only restarts what's actually running
- 🎨 **Visual design**: All scripts use emojis and clear formatting for easier scanning
