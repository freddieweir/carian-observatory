# Security Policy for Carian Observatory

## 🛡️ Security Requirements

### Critical Domain Protection
- **NEVER commit** production domain `corporateseas.com`
- **ALWAYS use** `yourdomain.com` in template files
- **VERIFY** generated files are gitignored

### Template System Security
- Files in `templates/` are safe to commit
- Files in `scripts/` and `services/*/configs/` are generated and gitignored
- Use `create-all-from-templates.sh` to generate working files

### Secret Management
- Use 1Password references: `{{ op://vault/item/field }}`
- Store real values in gitignored `.env` file
- Never commit API keys, tokens, or certificates

## 🚨 Reporting Security Issues

If you discover a security vulnerability:
1. **DO NOT** open a public issue
2. Email security@example.com
3. Include steps to reproduce
4. We'll respond within 24 hours

## ✅ Security Checklist

Before every commit:
- [ ] Run `./scripts/local-security-check.sh`
- [ ] Verify no production domains
- [ ] Check `.env` is not committed
- [ ] Validate template compliance

## 🔧 Security Tools

- GitLeaks: Secret detection
- TruffleHog: Additional secret scanning
- Trivy: Vulnerability scanning
- CodeQL: Static analysis
- Semgrep: Security patterns

## 📋 Compliance Standards

- PCI DSS (if handling payments)
- SOC 2 Type II (if applicable)
- GDPR (if handling EU data)
- Industry best practices for container security