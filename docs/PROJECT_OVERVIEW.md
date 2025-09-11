# Project Overview: Ollama-WebUI-Nginx-Perplexica Stack

## 🎯 Project Goals

This project creates a unified Docker Compose stack that combines:
- **Ollama** (LLM backend)
- **Open-WebUI** (Web interface)
- **Perplexica** (AI-powered search)
- **SearxNG** (Privacy-focused search engine)
- **Nginx** (Reverse proxy with HTTPS)
- **Watchtower** (Auto-updates)

**Key Requirements Addressed:**
✅ Local network only (yourdomain.com domain)  
✅ Multi-machine support (Mac Mini, M4 Max, M2 MBA)  
✅ iOS device compatibility  
✅ HTTPS with self-signed certificates  
✅ Deploy once, replicate everywhere  
✅ Minimal SSL configuration pain  

## 📁 Project Structure

```
ollama-webui-nginx-perplexica/
├── 🐳 Docker Compose Files
│   ├── docker-compose.yaml          # Main HTTPS setup
│   └── docker-compose.simple.yaml   # HTTP-only for testing
│
├── 🌐 Nginx Configuration
│   ├── nginx/https.conf              # HTTPS proxy config
│   └── nginx/http.conf               # HTTP proxy config
│
├── ⚙️ Service Configuration
│   ├── config/perplexica.toml        # Perplexica settings
│   └── config/searxng/settings.yml   # SearxNG configuration
│
├── 🔐 Setup Scripts (scripts/)
│   ├── setup.sh                     # Interactive setup wizard
│   └── setup-ssl.sh                 # SSL certificate generator
│
├── 📋 Documentation & Config
│   ├── README.md                    # Complete setup guide
│   ├── PROJECT_OVERVIEW.md          # This file
│   ├── .env.example                 # Environment template
│   └── .gitignore                   # Git ignore rules
│
└── 📦 Generated (not in repo)
    ├── ssl_cert/                    # SSL certificates
    ├── .env                         # Local environment
    └── volumes/                     # Docker data volumes
```

## 🌐 Network Architecture

### Domain Strategy
- **Mac Mini**: `webui.yourdomain.com`, `perplexica.yourdomain.com`
- **M4 Max**: `webui-m4.yourdomain.com`, `perplexica-m4.yourdomain.com`
- **M2 MBA**: `webui-m2.yourdomain.com`, `perplexica-m2.yourdomain.com`

### Service Communication
```
Internet/LAN
    ↓
Nginx (80/443) ← SSL Termination
    ↓
┌─────────────────────────────────────┐
│         Docker Network              │
│  ┌─────────────┐  ┌─────────────┐   │
│  │ Open-WebUI  │  │ Perplexica  │   │
│  │   :8080     │  │    :3000    │   │
│  └─────────────┘  └─────────────┘   │
│         ↓                ↓          │
│  ┌─────────────┐  ┌─────────────┐   │
│  │   Ollama    │  │  SearxNG    │   │
│  │   :11434    │  │    :8080    │   │
│  └─────────────┘  └─────────────┘   │
└─────────────────────────────────────┘
```

## 🚀 Deployment Workflow

### Initial Setup (Any Machine)
1. **Clone repository**
2. **Run setup wizard**: `./scripts/setup.sh`
3. **Choose HTTPS or HTTP setup**
4. **Configure DNS** (for HTTPS)
5. **Access services**

### Multi-Machine Replication
1. **Git pull** on new machine
2. **Run setup wizard**: `./scripts/setup.sh`
3. **Update DNS entries** with new machine IP
4. **Services automatically available**

## 🔐 Security Implementation

### SSL/TLS Strategy
- **Self-signed certificates** for local development
- **Individual certificates** per subdomain
- **Wildcard certificate** as backup
- **Modern TLS protocols** (1.2, 1.3)
- **Security headers** implemented

### Privacy Features
- **SearxNG** for private searching
- **Telemetry disabled** in Open-WebUI
- **Local-only** network access
- **No external dependencies** for core functionality

## 📱 iOS Compatibility

### Certificate Trust Process
1. **Visit HTTPS URL** on iOS device
2. **Accept security warning**
3. **Install certificate** via Settings
4. **Enable full trust** in Certificate Trust Settings

### Access Methods
- **Direct domain access** (after DNS setup)
- **IP-based access** (HTTP mode)
- **Bookmark support** for home screen

## 🔧 Maintenance & Updates

### Automated Updates (Watchtower)
- **Open-WebUI**: Auto-updated every 5 minutes
- **Ollama**: Auto-updated every 5 minutes
- **Perplexica**: Auto-updated every 5 minutes
- **Other services**: Manual updates for stability

### Manual Maintenance
```bash
# Update all services
docker compose pull && docker compose up -d

# View logs
docker compose logs -f [service-name]

# Restart specific service
docker compose restart [service-name]

# Backup data
# (See README.md for backup commands)
```

## 🎛️ Configuration Options

### Environment Variables (.env)
- **API Keys**: OpenRouter, OpenAI, etc.
- **Service Tags**: Docker image versions
- **Resource Limits**: Memory constraints
- **Debug Options**: Development settings

### Service Customization
- **Perplexica**: AI model selection, search engines
- **SearxNG**: Search engines, privacy settings
- **Open-WebUI**: Themes, features, integrations
- **Nginx**: SSL settings, proxy configuration

## 🔍 Troubleshooting Guide

### Common Issues
1. **SSL Certificate Problems**
   - Regenerate: `rm -rf ssl_cert/ && ./scripts/setup-ssl.sh`
   - Check validity: `openssl x509 -in ssl_cert/[domain].crt -text`

2. **DNS Resolution Issues**
   - Verify Eero DNS entries
   - Clear device DNS cache
   - Test with `nslookup [domain]`

3. **Service Connection Problems**
   - Check service status: `docker compose ps`
   - Review logs: `docker compose logs [service]`
   - Restart services: `docker compose restart`

4. **Port Conflicts**
   - Check port usage: `lsof -i :80` / `lsof -i :443`
   - Stop conflicting services
   - Modify compose file ports if needed

## 📊 Performance Considerations

### Resource Requirements
- **Mac Mini (24GB)**: Full stack, no limits
- **M4 Max (128GB)**: Full stack, optimal performance
- **M2 MBA (16GB)**: Resource limits recommended

### Optimization Tips
- **Use resource limits** for lower-spec machines
- **Enable GPU support** for M-series Macs
- **Monitor container resources** with `docker stats`
- **Regular cleanup** of unused images/volumes

## 🔄 Future Enhancements

### Potential Additions
- **Grafana/Prometheus** for monitoring
- **Backup automation** scripts
- **Load balancing** for multiple instances
- **VPN integration** for remote access
- **Custom domain** SSL certificate support

### Scalability Options
- **Docker Swarm** for clustering
- **Kubernetes** deployment
- **Cloud deployment** adaptations
- **CI/CD pipeline** integration

## 📈 Success Metrics

### Deployment Goals ✅
- ✅ **Single command deployment**
- ✅ **Cross-machine compatibility**
- ✅ **HTTPS security implementation**
- ✅ **iOS device accessibility**
- ✅ **Minimal SSL configuration pain**
- ✅ **Local network isolation**
- ✅ **Auto-update capability**

### User Experience Goals ✅
- ✅ **Intuitive setup process**
- ✅ **Clear documentation**
- ✅ **Troubleshooting guidance**
- ✅ **Flexible deployment options**
- ✅ **Professional SSL setup**

## 🤝 Contributing

### Development Workflow
1. **Fork repository**
2. **Create feature branch**
3. **Test on multiple machines**
4. **Update documentation**
5. **Submit pull request**

### Testing Checklist
- [ ] HTTP setup works
- [ ] HTTPS setup works
- [ ] SSL certificates generate correctly
- [ ] All services start successfully
- [ ] iOS devices can access services
- [ ] DNS configuration is correct
- [ ] Auto-updates function properly

---

**Project Status**: ✅ **Complete and Ready for Deployment**

This comprehensive stack provides a production-ready local development environment that meets all specified requirements while maintaining security, usability, and scalability.
