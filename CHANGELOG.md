# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive test suite with unit and integration tests
- Docker Compose validation tests
- Template generation unit tests
- CONTRIBUTING.md with contribution guidelines
- SECURITY.md with security policy and best practices
- CHANGELOG.md for tracking project changes
- Tests README with testing documentation
- Authelia service README with setup instructions

### Fixed
- **[CRITICAL]** Restored missing Authelia service directory and templates
- **[SECURITY]** Fixed CORS vulnerability in iframe-proxy.conf (changed from `Access-Control-Allow-Origin: *` to origin-based)
- **[SECURITY]** Fixed invalid X-Frame-Options header (changed from "ALLOWALL" to "SAMEORIGIN")
- Removed accidentally committed backup file (.pre-commit-config.yaml.backup)

### Changed
- Replaced multi-language CI workflow with infrastructure-focused validation
- Updated CI workflow to validate Docker Compose, shell scripts, and YAML files
- CI workflow now includes ShellCheck linting and security checks

### Removed
- Outdated .pre-commit-config.yaml.backup file

## [0.2.0] - 2025-09-29

### Added
- Proactive session expiry detection
- Multi-language build and test workflow (later replaced)
- Session monitoring capabilities

### Fixed
- OPSEC: Removed .mcp.json from tracking and added to gitignore

## [0.1.0] - 2025-09-29

### Added
- Initial repository structure
- Docker Compose orchestration with modular service includes
- Authelia authentication with WebAuthn/FIDO2 and TOTP 2FA
- Open-WebUI for AI chat interface
- Perplexica with SearXNG for AI-powered search
- Nginx reverse proxy with SSL/TLS termination
- Homepage dashboard for service overview
- Glance RSS feed integration
- Full observability stack (Prometheus, Grafana, Loki, Alertmanager)
- 1Password Connect integration for secret management
- Dual Watchtower configuration (production + canary)
- Template-based configuration system
- Comprehensive .gitignore (516 lines)
- GitLeaks secret detection configuration
- Pre-commit hooks for security validation
- GitHub Actions security workflows:
  - Security matrix orchestration
  - Domain sanitization checks
  - Template compliance validation
  - Dependency vulnerability scanning (Trivy)
  - SAST analysis (CodeQL + Semgrep)
- Dependabot configuration for automated updates
- Co-located template file structure
- Template generation script (create-all-from-templates.sh)
- Comprehensive README with architecture documentation

### Security
- Template system prevents secrets in version control
- Domain sanitization workflow prevents production domain leaks
- GitLeaks pre-commit hooks for secret detection
- Trivy weekly dependency scanning
- All services behind Authelia authentication
- Redis session storage with encryption
- Brute force protection (3 attempts, 5min ban)
- Health checks for all critical services

---

## Release Notes Guidelines

### Version Format
- **Major.Minor.Patch** (e.g., 1.2.3)
- **Major**: Breaking changes, major architectural updates
- **Minor**: New features, service additions, significant enhancements
- **Patch**: Bug fixes, security patches, minor improvements

### Change Categories

#### Added
New features, services, or capabilities:
```markdown
- New service integration (e.g., "Added PostgreSQL database service")
- New functionality (e.g., "Added automatic backup scheduling")
- New documentation (e.g., "Added troubleshooting guide")
```

#### Changed
Modifications to existing features:
```markdown
- Updated service configuration (e.g., "Changed Authelia session timeout to 1 hour")
- Improved performance (e.g., "Optimized nginx caching strategy")
- Refactored code (e.g., "Reorganized template directory structure")
```

#### Deprecated
Features marked for removal:
```markdown
- Deprecated old configuration format (will be removed in v2.0.0)
- Deprecated HTTP endpoints (HTTPS required in next major version)
```

#### Removed
Removed features or services:
```markdown
- Removed unused PostgreSQL service
- Removed deprecated configuration files
- Removed legacy migration scripts
```

#### Fixed
Bug fixes and issue resolutions:
```markdown
- Fixed Docker Compose validation error in nginx service
- Fixed template generation for special characters
- Fixed health check failing for Authelia service
- **[SECURITY]** Fixed authentication bypass vulnerability
```

#### Security
Security-related changes (always marked with `[SECURITY]` tag):
```markdown
- **[SECURITY]** Updated base images to patch CVE-2024-XXXXX
- **[SECURITY]** Implemented rate limiting on authentication endpoints
- **[SECURITY]** Rotated all default secrets and API keys
```

### Change Priority Indicators

- **[CRITICAL]**: Requires immediate attention, breaking change, or system-down fix
- **[SECURITY]**: Security-related change, vulnerability fix, or security enhancement
- **[BREAKING]**: Breaking change requiring manual intervention
- **[DEPRECATED]**: Feature marked for future removal

### Example Entry

```markdown
## [1.2.3] - 2025-11-15

### Added
- PostgreSQL database service with automatic backups
- Grafana dashboard for authentication metrics
- Health check endpoints for all services

### Changed
- Updated Authelia to v4.38.0 for improved WebAuthn support
- Migrated from SQLite to PostgreSQL for better concurrency
- Improved template generation script performance

### Fixed
- **[SECURITY]** Fixed CSRF vulnerability in authentication flow
- Fixed nginx configuration for websocket connections
- Fixed Prometheus scraping interval for Redis exporter

### Deprecated
- SQLite storage backend (will be removed in v2.0.0)

### Removed
- Legacy authentication scripts (replaced by Authelia)
```

---

## Migration Guides

### Upgrading from 0.1.x to 0.2.x

No breaking changes. Simply pull latest changes and restart services:

```bash
git pull origin main
docker compose down
docker compose up -d
```

### Future Major Version Upgrades

Major version upgrades (e.g., 1.x to 2.x) will include:
- Migration guide in release notes
- Backup/restore instructions
- Step-by-step upgrade procedure
- Rollback instructions if needed

---

## Maintenance Schedule

### Regular Updates
- **Docker Images**: Automated via Watchtower (daily canary, weekly production)
- **Dependencies**: Automated via Dependabot (weekly)
- **Security Patches**: As needed (ASAP for critical vulnerabilities)

### Planned Features
See [GitHub Issues](https://github.com/freddieweir/carian-observatory/issues) for upcoming features and enhancements.

---

## Versioning Policy

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Incompatible API changes or breaking changes
- **MINOR** version: Backwards-compatible functionality additions
- **PATCH** version: Backwards-compatible bug fixes

### Pre-release Versions
- **Alpha**: `1.0.0-alpha.1` - Early testing, unstable
- **Beta**: `1.0.0-beta.1` - Feature complete, testing
- **RC**: `1.0.0-rc.1` - Release candidate, final testing

---

## Links

- [Repository](https://github.com/freddieweir/carian-observatory)
- [Issues](https://github.com/freddieweir/carian-observatory/issues)
- [Pull Requests](https://github.com/freddieweir/carian-observatory/pulls)
- [Security Policy](SECURITY.md)
- [Contributing Guide](CONTRIBUTING.md)

---

**Last Updated**: 2025-11-09
