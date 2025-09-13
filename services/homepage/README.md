# Homepage Dashboard - TL;DR Guide

> **Enterprise dashboard for Carian Observatory AI Infrastructure Platform**

## 🚀 Quick Start

```bash
# Generate working scripts with your domain
cd scripts && ./create-scripts.sh

# Start Homepage dashboard
./start-homepage.sh

# Access dashboard
https://homepage.yourdomain.com
```

## 📋 Quick Commands Table

| 🎯 Task | 📝 Command | 📄 Description |
|---------|------------|----------------|
| 🔄 **Generate Scripts** | `./create-scripts.sh` | Create working scripts from templates |
| 🚀 **Start Dashboard** | `./start-homepage.sh` | Generate config and start service |
| ⚡ **Quick Config** | `./generate-config.sh` | Update service links from template |
| 🔍 **Check Status** | `docker ps --filter "name=co-homepage"` | View Homepage container status |
| 📊 **View Logs** | `docker logs co-homepage-service` | Check Homepage service logs |
| 🔄 **Restart Service** | `docker restart co-homepage-service` | Restart after config changes |

## 🎯 Adding New Services to Dashboard

### 1️⃣ Update Services Template
Edit `configs/services.yaml.template`:
```yaml
- Service Group:
    - Your New Service:
        href: https://newservice.${PRIMARY_DOMAIN}
        description: What this service does
        icon: si-service-icon  # See https://simpleicons.org
```

### 2️⃣ Update Environment Variables
Add to `.env` file:
```bash
NEWSERVICE_SUBDOMAIN=newservice
NEWSERVICE_DOMAIN=${NEWSERVICE_SUBDOMAIN}.${PRIMARY_DOMAIN}
```

### 3️⃣ Generate and Apply
```bash
cd scripts
./generate-config.sh    # Updates services.yaml
docker restart co-homepage-service
```

## 🔐 Template Security System

| 📁 File Type | 🔒 Git Status | 📄 Description |
|-------------|---------------|----------------|
| `*.template` | ✅ **Committed** | Safe templates with yourdomain.com |
| `create-scripts.sh` | ✅ **Committed** | Script generator (domain-safe) |
| `*.sh` scripts | ❌ **Gitignored** | Generated with real domains |
| `services.yaml` | ❌ **Gitignored** | Generated with real service URLs |

### 🛡️ Security Rules
- **✅ Always Commit**: Template files with `yourdomain.com` placeholders
- **❌ Never Commit**: Generated scripts or configs with real domains
- **🔄 Auto-Generated**: Working files created locally from templates

## 📊 Service Architecture

```
Homepage Dashboard (co-homepage-service)
├── 🌐 Web Interface (Port 3000)
├── 🔧 Configuration Templates
│   ├── services.yaml.template → services.yaml
│   └── settings.yaml (static)
├── 📜 Script Templates
│   ├── start-homepage.sh.template → start-homepage.sh
│   └── generate-config.sh.template → generate-config.sh
└── 🔗 Service Integration
    ├── Open-WebUI (Production & Canary)
    ├── Perplexica AI Search
    └── Authelia Authentication
```

## 🛠️ Configuration Management

### Environment Variables Used
```bash
PRIMARY_DOMAIN=yourdomain.com           # Your actual domain
WEBUI_DOMAIN=webui.${PRIMARY_DOMAIN}    # Open-WebUI URL
CANARY_DOMAIN=webui-canary.${PRIMARY_DOMAIN}
PERPLEXICA_DOMAIN=perplexica.${PRIMARY_DOMAIN}
AUTH_DOMAIN=auth.${PRIMARY_DOMAIN}
```

### Theme Configuration
Edit `configs/settings.yaml`:
```yaml
theme: dark              # or light
headerStyle: clean       # or boxed, underlined
title: Your Platform Name
```

## 🚨 Troubleshooting

| ⚠️ Issue | 🔍 Check | 💡 Solution |
|----------|----------|------------|
| **Dashboard won't start** | `docker logs co-homepage-service` | Run `./generate-config.sh` first |
| **Links don't work** | Service URLs in dashboard | Update `services.yaml.template` |
| **JavaScript errors** | Browser console | Check `settings.yaml` syntax |
| **SSL issues** | nginx configuration | Verify domains in nginx config |
| **Services missing** | Docker containers | Check service container names |

### Common Issues
```bash
# JavaScript theme errors
# Fix: Remove unsupported color properties from settings.yaml

# Service links broken
# Fix: Regenerate config with ./generate-config.sh

# Dashboard inaccessible
# Fix: Check nginx routing and SSL certificates
```

## 📁 Key Files

| 📄 File | 🎯 Purpose | 🔒 Status |
|---------|------------|-----------|
| `services.yaml.template` | Service definitions template | ✅ Committed |
| `settings.yaml` | Dashboard theme/layout | ✅ Committed |
| `docker-compose.yml` | Container configuration | ✅ Committed |
| `create-scripts.sh` | Script generator | ✅ Committed |
| `services.yaml` | Generated service config | ❌ Gitignored |
| `*.sh` scripts | Working scripts | ❌ Gitignored |

## 🎨 Icon Configuration

Use Simple Icons for service icons:
- **Format**: `si-service-name` (e.g., `si-openai`, `si-docker`)
- **Browse**: https://simpleicons.org
- **Custom Icons**: Place in `configs/icons/` directory

## 💡 Pro Tips

### Development Workflow
```bash
# 1. Edit templates (safe for git)
vim configs/services.yaml.template
vim scripts/start-homepage.sh.template

# 2. Generate working files (local only)
./create-scripts.sh

# 3. Apply changes
./start-homepage.sh
```

### Adding Service Groups
```yaml
# New service group in services.yaml.template
- Infrastructure:
    - Nginx Proxy:
        href: https://proxy.${PRIMARY_DOMAIN}
        description: Reverse proxy and SSL termination
        icon: si-nginx

    - Redis Cache:
        href: https://redis.${PRIMARY_DOMAIN}
        description: In-memory data store
        icon: si-redis
```

## 🔗 Related Documentation

- [Carian Observatory Main Documentation](../../README.md)
- [Service Management Guide](../../docs/service-management.md)
- [Security Best Practices](../../docs/security.md)
- [Template System Guide](../../docs/template-system.md)

---

**🎯 Homepage Dashboard provides centralized access to all platform services with enterprise-grade security and template-based domain management.**