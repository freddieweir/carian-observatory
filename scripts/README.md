# Scripts Directory

This directory contains all automation scripts for the Athena Core AI infrastructure, organized by functionality for easy navigation and management.

## Directory Structure

```
scripts/
├── README.md                    # This file
├── authentication/             # User authentication & 2FA management
├── certificates/               # SSL/TLS certificate management
├── deployment/                 # Service deployment scripts
├── infrastructure/             # Core infrastructure management
├── migration/                  # Project migration & setup
├── monitoring/                 # Health checks & monitoring
└── onepassword/               # 1Password integration & secrets
```

## Quick Reference

### Most Common Operations

```bash
# 🚀 Start services with secrets
./scripts/infrastructure/start-with-secrets.sh

# 🔐 Deploy API keys from 1Password
./scripts/onepassword/deploy-api-keys.sh

# 🔄 Smart service restart
./scripts/infrastructure/smart-restart.sh

# 🏥 Health check all services
./scripts/infrastructure/health-check.sh

# 🔑 Manage 2FA setup
./scripts/authentication/manage-2fa.sh
```

## Script Categories

### 🔐 Authentication (`authentication/`)

Scripts for managing user authentication, 2FA, and hardware keys:

- `generate-password-hash.sh` - Generate Argon2 password hashes for Authelia
- `manage-2fa.sh` - Interactive 2FA management (reset, setup, backup codes)
- `manage-yubikey.sh` - YubiKey registration and hardware authentication
- `monitor-2fa-setup.sh` - Monitor TOTP registration and display QR codes

**Quick Examples:**
```bash
# Generate password hash for user
./scripts/authentication/generate-password-hash.sh "mypassword"

# Reset user's 2FA
./scripts/authentication/manage-2fa.sh reset user@domain.com

# Monitor TOTP setup process
./scripts/authentication/monitor-2fa-setup.sh
```

### 🔒 Certificates (`certificates/`)

Scripts for SSL/TLS certificate management and deployment:

- `deploy-certificates.sh` - Deploy certificates from 1Password to nginx
- `get-ssl-cert.sh` - Generate SSL certificates for domains
- `migrate-certs-simple.sh` - Migrate certificates between locations
- `setup-ssl.sh` - Interactive SSL certificate setup wizard

**Quick Examples:**
```bash
# Generate certificate for domain
./scripts/certificates/get-ssl-cert.sh webui-m4.yourdomain.com

# Deploy certificates from 1Password
./scripts/certificates/deploy-certificates.sh

# SSL setup wizard
./scripts/certificates/setup-ssl.sh
```

### 🚀 Infrastructure (`infrastructure/`)

Core infrastructure management and service operations:

- `deploy-config.sh` - Deploy configuration files with environment variable injection
- `health-check.sh` - Comprehensive system health monitoring
- `manage-hosts.sh` - Manage /etc/hosts file entries
- `sanitize-domains.sh` - Clean and validate domain configurations
- `setup.sh` - Interactive project setup wizard
- `smart-restart.sh` - Intelligent service restart with dependency management
- `start-services.sh` - Start Docker Compose services
- `start-with-secrets.sh` - Secure startup with 1Password secret deployment

**Quick Examples:**
```bash
# Start all services with secrets
./scripts/infrastructure/start-with-secrets.sh

# Smart restart (detects what needs restarting)
./scripts/infrastructure/smart-restart.sh

# Comprehensive health check
./scripts/infrastructure/health-check.sh

# Interactive setup wizard
./scripts/infrastructure/setup.sh
```

### 📦 Migration (`migration/`)

Scripts for project migration, portfolio preparation, and major upgrades:

- `init-portfolio-migration.sh` - Initialize portfolio security migration
- `migrate-to-modular.sh` - Migrate to modular Docker Compose structure
- `migration-steps.sh` - Core migration step implementations
- `portfolio-security-migration.sh` - Complete portfolio security transformation
- `show-migration-summary.sh` - Display migration status and summary

**Quick Examples:**
```bash
# Initialize portfolio migration
./scripts/migration/init-portfolio-migration.sh

# Show migration status
./scripts/migration/show-migration-summary.sh

# Complete security migration
./scripts/migration/portfolio-security-migration.sh
```

### 👀 Monitoring (`monitoring/`)

Health monitoring, canary testing, and system observability:

- `monitor_canary.sh` - Monitor canary deployment health and status
- `request_canary_test.sh` - Automated testing of canary endpoints

**Quick Examples:**
```bash
# Monitor canary deployment
./scripts/monitoring/monitor_canary.sh

# Test canary endpoints
./scripts/monitoring/request_canary_test.sh
```

### 🔐 1Password (`onepassword/`)

1Password Connect Server and secrets management integration:

- `connect-api.sh` - REST API client for 1Password Connect Server
- `demo-1password-setup.sh` - Interactive demo and setup guide
- `deploy-api-keys.sh` - Deploy API keys from 1Password (CLI or Connect Server)
- `manage-connect-server.sh` - 1Password Connect Server lifecycle management
- `migrate-certs-to-1password.sh` - Migrate SSL certificates to 1Password storage

**Quick Examples:**
```bash
# Start Connect Server
./scripts/onepassword/manage-connect-server.sh start

# Generate access token
./scripts/onepassword/manage-connect-server.sh token create

# Deploy API keys (auto-detects method)
./scripts/onepassword/deploy-api-keys.sh

# Test Connect Server API
./scripts/onepassword/connect-api.sh health

# Interactive setup demo
./scripts/onepassword/demo-1password-setup.sh
```

## Script Execution Patterns

### Always from Project Root
All scripts should be executed from the project root directory:
```bash
# ✅ Correct
./scripts/category/script-name.sh

# ❌ Incorrect
cd scripts/category && ./script-name.sh
```

### Common Parameters
Most scripts support standard parameters:
- `-h, --help` - Show help and usage information
- `-v, --validate` - Validate configuration without making changes
- `-d, --dry-run` - Show what would be done without executing
- `-q, --quiet` - Suppress non-essential output

### Environment Variables
Many scripts respect common environment variables:
- `CONNECT_TOKEN` - 1Password Connect Server access token
- `CONNECT_API_URL` - Connect Server URL (default: http://localhost:8090)
- `DEBUG_MODE` - Enable verbose debugging output

## Maintenance

### Adding New Scripts
When adding new scripts:
1. Choose the appropriate category directory
2. Use the established naming convention (kebab-case)
3. Include proper shebang, error handling, and help text
4. Make the script executable: `chmod +x script-name.sh`
5. Update this README with the new script

### Script Standards
All scripts should:
- Use `set -euo pipefail` for safety
- Include comprehensive help text (`--help`)
- Use colored output for better UX
- Handle errors gracefully with informative messages
- Work when executed from project root

## Dependencies

Most scripts require:
- **Docker & Docker Compose** - Container management
- **1Password CLI (op)** - Secret management (for 1Password scripts)
- **curl** - HTTP requests and API calls
- **jq** - JSON processing (for API scripts)

Optional dependencies:
- **openssl** - Certificate generation and validation
- **qrencode** - QR code generation (for 2FA setup)

## Security Notes

- Scripts handle sensitive data (certificates, API keys, passwords)
- Temporary files use secure permissions (600)
- No sensitive data is logged or echoed to stdout
- All 1Password operations use encrypted storage
- Scripts validate inputs and fail safely on errors

For detailed information about specific scripts, run:
```bash
./scripts/category/script-name.sh --help
```