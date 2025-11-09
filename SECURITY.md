# Security Policy

## Supported Versions

Carian Observatory is an infrastructure-as-code project using Docker containers with rolling releases. Security updates are applied to:

| Version | Supported          | Update Strategy |
| ------- | ------------------ | --------------- |
| Latest (main branch) | ✅ Yes | Immediate security patches |
| Docker Images | ✅ Yes | Automated via Watchtower & Dependabot |
| Previous releases | ❌ No | Upgrade to latest recommended |

## Security Architecture

### Multi-Layer Security

1. **Authentication Layer** (Authelia)
   - WebAuthn/FIDO2 hardware key support
   - TOTP 2FA as backup
   - Session management with Redis
   - Brute force protection

2. **Network Layer**
   - Private Docker networks
   - No direct internet exposure of services
   - Reverse proxy (nginx) as single entry point
   - SSL/TLS termination

3. **Secret Management**
   - 1Password Connect API integration
   - Environment variable injection
   - No secrets in version control
   - Template-based configuration system

4. **Automated Security**
   - Dependabot for dependency updates
   - GitLeaks secret scanning
   - Trivy vulnerability scanning
   - Domain sanitization checks

## Reporting a Vulnerability

### DO NOT create public issues for security vulnerabilities!

#### Reporting Process

1. **Email security report** to: [Security Contact Email - Update with actual email]

   **Subject**: `[SECURITY] Brief description`

2. **Include in report**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Affected versions/components
   - Your contact information (optional)
   - Proof of concept (if applicable)

3. **Expected Response Times**:
   - **Initial response**: Within 48 hours
   - **Triage assessment**: Within 1 week
   - **Status updates**: Every 2 weeks
   - **Fix timeline**: Depends on severity (see below)

#### Severity Levels

| Severity | Description | Response Time | Examples |
|----------|-------------|---------------|----------|
| **Critical** | Immediate risk of data breach or system compromise | 24-48 hours | RCE, Authentication bypass, Secret exposure |
| **High** | Significant security impact | 1 week | Privilege escalation, CSRF, SQLi |
| **Medium** | Limited security impact | 2 weeks | XSS, Information disclosure |
| **Low** | Minimal security impact | 4 weeks | Minor config issues, outdated dependencies |

### What Happens Next

1. **Acknowledgment**: We confirm receipt of your report
2. **Validation**: We verify and reproduce the vulnerability
3. **Assessment**: We determine severity and impact
4. **Fix Development**: We develop and test a fix
5. **Disclosure**: We coordinate disclosure timeline with you
6. **Credit**: We acknowledge you in security advisory (if desired)

## Security Best Practices

### For Users/Operators

#### Initial Setup

- [ ] Generate strong random secrets: `openssl rand -hex 32`
- [ ] Use unique secrets for each service
- [ ] Enable WebAuthn/FIDO2 with hardware keys
- [ ] Configure TOTP as backup 2FA
- [ ] Secure your `.env` file: `chmod 600 .env`
- [ ] Never commit `.env` to version control

#### Domain Security

- [ ] Use HTTPS only (never HTTP for production)
- [ ] Obtain valid SSL/TLS certificates
- [ ] Configure HSTS headers
- [ ] Enable certificate auto-renewal
- [ ] Use strong ciphers in nginx config

#### Access Control

- [ ] Review Authelia access control rules regularly
- [ ] Use principle of least privilege
- [ ] Audit user access quarterly
- [ ] Rotate secrets every 90 days
- [ ] Monitor authentication logs

#### Container Security

- [ ] Run containers as non-root when possible
- [ ] Use read-only volumes where appropriate
- [ ] Limit container resources (CPU, memory)
- [ ] Keep Docker and Docker Compose updated
- [ ] Review Watchtower updates before applying

#### Monitoring

- [ ] Enable Prometheus alerting
- [ ] Monitor Grafana dashboards daily
- [ ] Review Loki logs for anomalies
- [ ] Set up alerting for failed auth attempts
- [ ] Monitor resource usage trends

#### Backup & Recovery

- [ ] Backup encryption keys securely
- [ ] Test restore procedures quarterly
- [ ] Store backups offline/off-site
- [ ] Document disaster recovery plan
- [ ] Encrypt backup data

### For Contributors

#### Code Security

- [ ] Never commit secrets or API keys
- [ ] Use templates with environment variables
- [ ] Validate all user inputs
- [ ] Sanitize command inputs to prevent injection
- [ ] Use parameterized queries (if adding DB features)
- [ ] Implement proper error handling (don't leak info)

#### Dependency Security

- [ ] Pin Docker image versions with SHA256 digests
- [ ] Review Dependabot PRs before merging
- [ ] Check for known vulnerabilities (Trivy scans)
- [ ] Update dependencies regularly
- [ ] Remove unused dependencies

#### CI/CD Security

- [ ] Use least privilege for GitHub Actions
- [ ] Pin action versions to full SHA
- [ ] Never log secrets in CI output
- [ ] Use environment protection rules
- [ ] Enable branch protection

## Security Features

### Automated Security Scanning

#### GitLeaks - Secret Detection
```yaml
# Pre-commit hook
- repo: https://github.com/gitleaks/gitleaks
  hooks:
    - id: gitleaks
```

**What it catches**:
- API keys (OpenAI, Claude, etc.)
- Generic secrets
- Private keys
- Passwords in configs

#### Trivy - Vulnerability Scanning
```yaml
# Weekly dependency scan
- name: Run Trivy scanner
  uses: aquasecurity/trivy-action@master
```

**What it scans**:
- Docker image vulnerabilities
- OS package vulnerabilities
- Known CVEs

#### Domain Sanitization
```yaml
# Prevents production domain leaks
- name: Check for production domains
  run: ./scripts/sanitize-repository.sh
```

**What it prevents**:
- Production domain in templates
- Personal information leaks
- Hardcoded production values

### Runtime Security

#### Authelia Configuration

**Session Security**:
```yaml
session:
  cookies:
    - expiration: 1h      # Auto-logout after 1 hour
      inactivity: 5m       # Lock after 5 minutes idle
      same_site: lax       # CSRF protection
      secure: true         # HTTPS only
```

**Brute Force Protection**:
```yaml
regulation:
  max_retries: 3          # Lock after 3 failed attempts
  find_time: 2m           # Detection window
  ban_time: 5m            # Temporary ban duration
```

**Access Control**:
```yaml
access_control:
  default_policy: deny    # Deny all by default
  rules:
    - domain: '*.example.com'
      policy: two_factor   # Require 2FA
```

#### Nginx Security Headers

```nginx
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

## Known Security Considerations

### Design Decisions

#### Using `:latest` Tags
**Risk**: Potential breaking changes, reproducibility issues
**Mitigation**: Watchtower canary testing, health checks, rollback capability
**Future**: Plan to pin versions with SHA256 digests

#### Shared Docker Network
**Risk**: Services can communicate directly
**Mitigation**: Minimal network exposure, Authelia auth layer
**Accepted Risk**: Required for service integration

#### SQLite for Authelia
**Risk**: Not suitable for high concurrency
**Mitigation**: Single-user/small team deployment only
**Future**: Optional PostgreSQL backend planned

### Out of Scope

The following are **not** security issues for this project:

- DoS attacks (infrastructure-level protection required)
- Physical access to host system
- Social engineering attacks
- Attacks requiring stolen credentials
- Issues in upstream Docker images (report to image maintainers)

## Security Checklist

### Pre-Deployment

- [ ] All secrets generated and stored securely (1Password)
- [ ] `.env` file configured with production values
- [ ] SSL/TLS certificates obtained and configured
- [ ] Authelia users created with strong passwords
- [ ] 2FA enrolled for all users
- [ ] Firewall configured (only ports 80, 443 exposed)
- [ ] Docker daemon secured (no TCP socket exposure)
- [ ] Host OS updated with security patches
- [ ] Fail2ban configured (optional but recommended)
- [ ] Backup system configured and tested

### Post-Deployment

- [ ] Verify HTTPS working correctly
- [ ] Test authentication flow
- [ ] Verify 2FA requirement enforced
- [ ] Check service health dashboards
- [ ] Review initial logs for errors
- [ ] Test backup/restore procedure
- [ ] Configure monitoring alerts
- [ ] Document admin credentials (in 1Password)

### Ongoing Maintenance

- [ ] **Weekly**: Review Dependabot PRs
- [ ] **Weekly**: Check Watchtower update logs
- [ ] **Monthly**: Review authentication logs
- [ ] **Monthly**: Check for failed login attempts
- [ ] **Quarterly**: Rotate secrets
- [ ] **Quarterly**: Audit user access
- [ ] **Quarterly**: Test disaster recovery
- [ ] **Annually**: Security audit/penetration test

## Security Resources

### Documentation
- [Authelia Security Documentation](https://www.authelia.com/overview/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Nginx Security](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)

### Tools
- [GitLeaks](https://github.com/gitleaks/gitleaks) - Secret scanning
- [Trivy](https://github.com/aquasecurity/trivy) - Vulnerability scanning
- [Docker Bench Security](https://github.com/docker/docker-bench-security) - Docker host security audit
- [Lynis](https://cisofy.com/lynis/) - System security audit

### Community
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

## Security Updates

Security fixes are announced via:
- GitHub Security Advisories
- Repository release notes
- CHANGELOG.md (marked with `[SECURITY]`)

Subscribe to:
- GitHub repository watches (releases only)
- GitHub Security Advisories for this repo

## Responsible Disclosure

We are committed to working with security researchers and will:

- Acknowledge your contribution
- Keep you updated on fix progress
- Credit you in security advisory (if desired)
- Work with you on disclosure timeline
- Not pursue legal action for good faith research

### Hall of Fame

Contributors who responsibly disclose security issues:
- _None yet - be the first!_

---

**Last Updated**: 2025-11-09

For security questions not covered here, contact: [Security Contact]

Thank you for helping keep Carian Observatory secure! 🔒
