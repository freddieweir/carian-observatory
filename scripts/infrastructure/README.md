# 🏗️ Infrastructure Scripts

Core infrastructure management tools for the Carian Observatory platform.

## 📋 Quick Copy Commands

| Task | Command | What it Does |
|------|---------|--------------|
| **🚀 Start Everything** | `./scripts/infrastructure/start-with-secrets.sh` | Starts all services with API keys from 1Password |
| **🔄 Smart Restart** | `./scripts/infrastructure/smart-restart.sh` | Intelligently restarts services |
| **🎯 Restart Canary Only** | `./scripts/infrastructure/smart-restart.sh canary` | Restarts canary environment |
| **💚 Health Check** | `./scripts/infrastructure/health-check.sh` | Comprehensive system health check |
| **🔧 Interactive Setup** | `./scripts/infrastructure/setup.sh` | First-time setup wizard |
| **📝 Deploy Config** | `./scripts/infrastructure/deploy-config.sh` | Process .env into service configs |

## 🎯 Main Scripts

### `start-with-secrets.sh` - Secure Startup with API Keys
Starts all services with API keys automatically injected from 1Password.

```bash
# Standard startup (auto-detects best 1Password method)
./scripts/infrastructure/start-with-secrets.sh

# Force specific method
./scripts/infrastructure/start-with-secrets.sh --method connect  # Use Connect Server
./scripts/infrastructure/start-with-secrets.sh --method cli      # Use 1Password CLI
```

**Features:**
- 🔐 Retrieves API keys from 1Password (Connect Server or CLI)
- 🚀 Starts all Docker services
- ✅ Validates configurations before starting
- 📊 Shows service status after startup

### `smart-restart.sh` - Intelligent Service Restart
Detects running services and restarts only what's needed.

```bash
# Restart all running services
./scripts/infrastructure/smart-restart.sh

# Restart specific environments
./scripts/infrastructure/smart-restart.sh canary      # Canary only
./scripts/infrastructure/smart-restart.sh production  # Production only

# Restart specific service
./scripts/infrastructure/smart-restart.sh authelia   # Just Authelia
```

**Smart Features:**
- 🧠 Detects which services are running
- 🎯 Targeted restarts (canary vs production)
- 📝 Preserves configurations
- 🔄 Handles dependencies correctly

### `health-check.sh` - System Health Monitor
Comprehensive health check with auto-recovery suggestions.

```bash
./scripts/infrastructure/health-check.sh
```

**What it checks:**
- 🐳 Docker daemon status
- 📦 Container health states
- 🌐 Service endpoint availability
- 💾 Disk space and memory
- 🔐 Authentication service status
- 🌍 Network connectivity

### `setup.sh` - Interactive Setup Wizard
First-time setup for the entire infrastructure.

```bash
./scripts/infrastructure/setup.sh
```

**Setup steps:**
1. 📝 Environment configuration
2. 🔐 1Password integration
3. 🔑 SSL certificate generation
4. 👤 User database creation
5. 🚀 Service initialization

### `deploy-config.sh` - Configuration Deployment
Processes environment variables into service configurations.

```bash
# Deploy all configurations
./scripts/infrastructure/deploy-config.sh

# Dry run (preview changes)
./scripts/infrastructure/deploy-config.sh --dry-run
```

## 🚀 Common Workflows

### First-Time Setup
```bash
# 1. Run interactive setup
./scripts/infrastructure/setup.sh

# 2. Configure 1Password
./scripts/onepassword/manage-connect-server.sh start

# 3. Start with secrets
./scripts/infrastructure/start-with-secrets.sh
```

### Daily Operations
```bash
# Morning startup
./scripts/infrastructure/start-with-secrets.sh

# Check health
./scripts/infrastructure/health-check.sh

# Smart restart if needed
./scripts/infrastructure/smart-restart.sh
```

### Troubleshooting Services
```bash
# 1. Run health check
./scripts/infrastructure/health-check.sh

# 2. Check specific service logs
docker logs co-authelia-service --tail 50

# 3. Smart restart problematic service
./scripts/infrastructure/smart-restart.sh authelia
```

## 📊 Service Architecture

```
┌─────────────────────────────────────────┐
│         Carian Observatory              │
├─────────────────────────────────────────┤
│                                         │
│  🔐 Authentication Stack                │
│  ├── co-authelia-service               │
│  └── co-authelia-redis                 │
│                                         │
│  🌐 Web Interface Stack                 │
│  ├── co-open-webui-service (prod)      │
│  └── co-open-webui-canary (test)       │
│                                         │
│  🔍 AI Search Stack                     │
│  ├── co-perplexica-service             │
│  └── co-perplexica-searxng             │
│                                         │
│  🌉 Infrastructure                      │
│  ├── co-nginx-service                  │
│  ├── co-1p-connect-sync                │
│  └── co-1p-connect-api                 │
│                                         │
│  🔄 Update Management                   │
│  ├── co-ow-watchtower-service (weekly) │
│  └── co-ow-watchtower-canary (daily)   │
│                                         │
└─────────────────────────────────────────┘
```

## 🛠️ Troubleshooting

### Services Won't Start
```bash
# Check Docker daemon
docker ps

# Run health check for diagnostics
./scripts/infrastructure/health-check.sh

# Check for port conflicts
lsof -i :8080  # Open-WebUI
lsof -i :9091  # Authelia
```

### Configuration Issues
```bash
# Validate environment file
cat .env | grep -E "^[A-Z_]+="

# Redeploy configurations
./scripts/infrastructure/deploy-config.sh

# Check deployed configs
docker exec co-authelia-service cat /config/configuration.yml
```

### 1Password Connection Issues
```bash
# Check Connect Server status
./scripts/onepassword/manage-connect-server.sh status

# Test API connection
./scripts/onepassword/connect-api.sh health

# Fallback to CLI method
./scripts/infrastructure/start-with-secrets.sh --method cli
```

## 📁 Key Files

| File/Directory | Purpose |
|----------------|---------|
| `.env` | Environment variables and secrets |
| `docker-compose.yml` | Master service definitions |
| `services/*/` | Modular service configurations |
| `configs/*/` | Service-specific config files |

## 🔗 Related Documentation
- [1Password Scripts](../onepassword/README.md)
- [Authentication Scripts](../authentication/README.md)
- [Certificate Management](../certificates/README.md)
- [Monitoring Scripts](../monitoring/README.md)