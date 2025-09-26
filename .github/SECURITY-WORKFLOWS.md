# GitHub Actions Security Workflows

This document describes the comprehensive security workflows for Carian Observatory that enforce domain sanitization, secret detection, and template compliance.

## 🔒 Workflow Overview

### Core Security Workflows

#### 1. `domain-sanitization.yml` - Domain Protection
**Purpose**: Prevents production domain exposure in commits
**Triggers**: Pull requests and pushes to main branch
**What it does**:
- Scans all text files for production domains (configurable)
- Blocks commits containing critical domains
- Validates template files only use placeholder domains
- Generates detailed scan reports with violations
- **CRITICAL**: Fails CI immediately if production domain found

#### 2. `secret-scanner.yml` - Secret Detection
**Purpose**: Detects API keys, tokens, and sensitive data
**Triggers**: Pull requests and pushes to main branch
**What it does**:
- **GitLeaks**: Scans for API keys (OpenAI, Claude, ElevenLabs, 1Password)
- **TruffleHog**: Additional verified secret detection
- Custom rules for JWT tokens, SSH keys, database URLs
- Allowlist for false positives (template references, env vars)
- Blocks commits with exposed secrets

#### 3. `template-compliance.yml` - Template System Validation
**Purpose**: Enforces template/script separation for security
**Triggers**: Pull requests only
**What it does**:
- Validates `.gitignore` excludes generated files
- Checks template directory structure
- Ensures scripts/ directory is not tracked
- Validates container naming convention (co- prefix)
- Verifies master generation script exists

#### 4. `dependency-check.yml` - Vulnerability Scanning
**Purpose**: Scans for vulnerable dependencies and Docker security
**Triggers**: Pull requests + weekly schedule
**What it does**:
- **Trivy**: Filesystem vulnerability scanning
- Docker Compose security analysis
- Checks for privileged containers, host networking
- Resource limit recommendations
- SARIF report generation for GitHub Security tab

#### 5. `sast-analysis.yml` - Static Application Security Testing
**Purpose**: Advanced code security analysis
**Triggers**: Pull requests and pushes to main
**What it does**:
- **CodeQL**: GitHub's semantic code analysis
- **Semgrep**: Pattern-based security scanning
- Supports JavaScript and Python codebases
- Security audit rules for Docker, secrets, general security
- Integrates with GitHub Security Advisory

#### 6. `security-matrix.yml` - Security Orchestrator
**Purpose**: Coordinates and summarizes all security checks
**Triggers**: Pull requests and manual dispatch
**What it does**:
- Matrix strategy for parallel security check execution
- Orchestrates domain, secret, template, and dependency checks
- Generates comprehensive security summary report
- Provides single point of security status overview

## 🔧 Configuration Files

### `.gitleaks.toml`
Custom GitLeaks configuration with:
- API key detection patterns
- Production domain blocking
- Allowlist for false positives
- Template domain exceptions

### `CODEOWNERS`
Requires security team review for:
- Root configuration files
- Template system files
- GitHub workflows
- Security-sensitive scripts

### `dependabot.yml`
Automated dependency updates for:
- Docker images
- GitHub Actions
- npm packages (if present)

### `.pre-commit-config.yaml`
Local pre-commit hooks for:
- GitLeaks secret scanning
- Production domain checks
- Template system validation
- Container naming compliance

## 🚀 Local Testing Scripts

### `scripts/local-security-check.sh`
Run before commits to catch issues early:
```bash
./scripts/local-security-check.sh
```
Performs same checks as CI workflows locally.

### `scripts/validate-templates.sh`
Validate template system compliance:
```bash
./scripts/validate-templates.sh
```
Ensures template structure is correct.

## 🛡️ Security Enforcement

### Critical Requirements
- ❌ **BLOCKS**: Production domains in any committed file
- ✅ **ALLOWS**: Template placeholder domains only
- 🔍 **DETECTS**: API keys, tokens, certificates
- 📋 **ENFORCES**: Template system compliance
- 🐳 **VALIDATES**: Container security best practices

### Environment Configuration
The workflows use configurable domain blocking via GitHub repository variables:

**Setting up domain protection**:
1. Go to your repository Settings → Secrets and variables → Actions
2. Add a repository variable named `PRODUCTION_DOMAIN`
3. Set the value to your actual production domain (e.g., `corporateseas.com`)
4. The workflows will automatically block this domain from being committed

**Default behavior**: If no `PRODUCTION_DOMAIN` variable is set, defaults to `corporateseas.com`

**Local testing**: Export `PRODUCTION_DOMAIN=your-domain.com` before running local security scripts

### Workflow Results
- **Pass**: All checks succeed, safe to merge
- **Fail**: Security violations found, provides clear fix instructions
- **Artifacts**: Scan results stored for 30 days
- **Reports**: Detailed violation summaries with file/line references

## 🔄 How They Work Together

1. **Pre-commit hooks** catch issues before commit
2. **Domain sanitization** runs first, fails fast on critical violations
3. **Secret detection** uses multiple tools for comprehensive coverage
4. **Template compliance** ensures infrastructure security
5. **Dependency scanning** catches vulnerable packages
6. **SAST analysis** provides deep code security insights
7. **Security matrix** orchestrates and summarizes everything

This creates multiple layers of security validation ensuring no production domains, secrets, or security vulnerabilities make it into the repository.