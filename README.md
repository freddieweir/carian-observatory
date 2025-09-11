# Carian Observatory

<img width="1000" height="563" alt="image" src="https://github.com/user-attachments/assets/38f7003b-92dd-47b2-8456-d71ddc27a1aa" />


A comprehensive AI infrastructure platform featuring enterprise security, modern authentication, and scalable microservices architecture.

## Quick Start

```bash
# Copy and configure environment
cp .env.example .env
# Edit .env with your settings

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
- **Authelia**: Authentication portal at `https://auth-m4.yourdomain.com`
- **Nginx**: Reverse proxy with SSL termination

### Architecture

```
services/
├── nginx/          # Reverse proxy and SSL
├── open-webui/     # Web UI for AI models
├── perplexica/     # AI search (includes SearXNG)
├── auth/           # Authelia + Redis authentication
└── monitoring/     # Watchtower auto-updates
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

## SSL Certificates

Place certificates in `services/nginx/ssl/`:
- `webui-m4.yourdomain.com.crt` + `.key`
- `perplexica-m4.yourdomain.com.crt` + `.key`
- `auth-m4.yourdomain.com.crt` + `.key`

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
