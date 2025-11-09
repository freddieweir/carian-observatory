# Contributing to Carian Observatory

Thank you for considering contributing to Carian Observatory! This document provides guidelines and instructions for contributing to this infrastructure-as-code project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Contributing Guidelines](#contributing-guidelines)
- [Testing](#testing)
- [Security](#security)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

### Our Standards

- **Be respectful**: Treat all contributors with respect and courtesy
- **Be collaborative**: Work together to improve the project
- **Be constructive**: Provide helpful feedback and suggestions
- **Be patient**: Remember that everyone was a beginner once

### Unacceptable Behavior

- Harassment, discrimination, or trolling
- Publishing others' private information
- Spam or off-topic content
- Any conduct that would be inappropriate in a professional setting

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Docker** 20.10+ and **Docker Compose** 2.20+
- **Git** for version control
- **Bash** 4.0+ for running scripts
- **ShellCheck** for linting shell scripts
- **yamllint** for YAML validation

### Initial Setup

1. **Fork the repository**:
   ```bash
   # On GitHub, click "Fork" button
   ```

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/carian-observatory.git
   cd carian-observatory
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/freddieweir/carian-observatory.git
   ```

4. **Create test environment**:
   ```bash
   cp .env.example .env
   # Edit .env with test values (use test.example.com domains)
   ```

5. **Generate configs from templates**:
   ```bash
   ./scripts/create-all-from-templates.sh
   ```

6. **Install pre-commit hooks** (optional but recommended):
   ```bash
   pip install pre-commit
   pre-commit install
   ```

## Development Workflow

### Branch Strategy

- `main` - Stable, production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features or enhancements
- `fix/*` - Bug fixes
- `docs/*` - Documentation updates
- `refactor/*` - Code refactoring

### Creating a Branch

```bash
# Update your local repository
git checkout main
git pull upstream main

# Create a feature branch
git checkout -b feature/your-feature-name
```

### Making Changes

1. **Make your changes** following the project structure
2. **Test locally** using the test suite
3. **Lint your code**:
   ```bash
   # Shell scripts
   shellcheck scripts/**/*.sh

   # YAML files
   yamllint .

   # Docker Compose
   docker compose config
   ```

4. **Update documentation** if adding new features

### Commit Message Guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes
- `perf`: Performance improvements
- `security`: Security fixes

**Examples**:

```bash
# Good commit messages
git commit -m "feat(authelia): add WebAuthn support for hardware keys"
git commit -m "fix(nginx): resolve CORS policy for iframe embedding"
git commit -m "docs(readme): update installation instructions for macOS"
git commit -m "test(compose): add validation for service dependencies"

# Bad commit messages
git commit -m "fixed stuff"
git commit -m "updates"
git commit -m "asdf"
```

## Contributing Guidelines

### Template Files

**CRITICAL**: Never commit production secrets or personal domains!

1. **Always use templates**: Create `.template` files for any configuration containing domain names or secrets
2. **Use placeholders**: Use `yourdomain.com` or environment variables like `${PRIMARY_DOMAIN}`
3. **Co-locate templates**: Place `.template` files alongside their generated counterparts
4. **Update .gitignore**: Ensure generated files are gitignored

**Example**:

```yaml
# ❌ BAD - services/myservice/config.yml
domain: freddieweir.com
api_key: super_secret_key_123

# ✅ GOOD - services/myservice/config.yml.template
domain: ${PRIMARY_DOMAIN}
api_key: ${MYSERVICE_API_KEY}
```

### Directory Structure

Follow the established structure:

```
carian-observatory/
├── services/
│   └── service-name/
│       ├── docker-compose.yml.template
│       ├── configs/
│       │   └── config.yml.template
│       └── README.md
├── scripts/
│   └── script-name.sh.template
└── .github/
    └── workflows/
```

### Docker Compose

1. **Use environment variables**: Never hardcode values
2. **Include health checks**: All services should have health checks
3. **Use semantic container names**: Follow `${USER_PREFIX}-service-name` pattern
4. **Document ports**: Comment on what each port is for
5. **Specify restart policies**: Use `restart: unless-stopped`

**Example**:

```yaml
services:
  myservice:
    image: myservice:latest
    container_name: ${USER_PREFIX}-myservice
    restart: unless-stopped
    environment:
      - SERVICE_API_KEY=${MYSERVICE_API_KEY}
    ports:
      - "${MYSERVICE_PORT}:8080"  # HTTP API
    healthcheck:
      test: ["CMD", "wget", "-q", "-O-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - app-network
```

### Shell Scripts

1. **Use bash shebang**: `#!/usr/bin/env bash`
2. **Enable strict mode**: `set -euo pipefail`
3. **Add documentation**: Include header comment explaining purpose
4. **Use shellcheck**: Lint with `shellcheck -x script.sh`
5. **Quote variables**: Always quote variables: `"$variable"`

**Example**:

```bash
#!/usr/bin/env bash
# Script purpose: Deploy service updates
# Usage: ./deploy.sh [service-name]

set -euo pipefail

readonly SERVICE="${1:-all}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
    echo "Deploying $SERVICE..."
    # Implementation
}

main "$@"
```

### YAML Files

1. **Use 2-space indentation**
2. **Use lowercase for keys**
3. **Include comments** for complex configurations
4. **Validate with yamllint**

### Security

**NEVER**:
- Commit secrets, API keys, or passwords
- Commit production domain names
- Include `.env` files (use `.env.example`)
- Disable security features without documentation

**ALWAYS**:
- Use environment variables for secrets
- Use templates with placeholders
- Run security scans (gitleaks, trivy)
- Document security implications

## Testing

### Running Tests

Before submitting a PR:

```bash
# Run all tests
./tests/run_all_tests.sh

# Run specific test suites
./tests/unit/test_template_generation.sh
./tests/integration/test_docker_compose.sh

# Validate Docker Compose
docker compose config

# Lint shell scripts
shellcheck scripts/**/*.sh
```

### Writing Tests

When adding features, add corresponding tests:

1. **Unit tests** for individual components (`tests/unit/`)
2. **Integration tests** for cross-service functionality (`tests/integration/`)

See `tests/README.md` for detailed testing guidelines.

## Pull Request Process

### Before Submitting

- [ ] Tests pass locally (`./tests/run_all_tests.sh`)
- [ ] Code is linted (shellcheck, yamllint)
- [ ] Documentation is updated
- [ ] Commit messages follow conventions
- [ ] No secrets or production domains in commits
- [ ] Templates use proper placeholders
- [ ] Changes are tested in clean environment

### Submitting PR

1. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request** on GitHub:
   - Use descriptive title following commit conventions
   - Fill out PR template completely
   - Reference related issues
   - Add screenshots for UI changes

3. **PR Title Format**:
   ```
   feat(service): add new monitoring dashboard
   fix(nginx): resolve SSL certificate renewal
   docs: update installation guide for Windows
   ```

4. **PR Description Template**:

   ```markdown
   ## Summary
   Brief description of changes

   ## Motivation
   Why is this change needed?

   ## Changes
   - Change 1
   - Change 2
   - Change 3

   ## Testing
   - [ ] Unit tests pass
   - [ ] Integration tests pass
   - [ ] Manual testing completed

   ## Screenshots (if applicable)
   [Add screenshots here]

   ## Checklist
   - [ ] No secrets or production domains committed
   - [ ] Templates updated with placeholders
   - [ ] Documentation updated
   - [ ] Tests added/updated
   - [ ] Changelog updated
   ```

### Review Process

1. **Automated checks** must pass:
   - CI/CD workflows (GitHub Actions)
   - Security scans (GitLeaks, Trivy)
   - Template compliance
   - Domain sanitization

2. **Code review** by maintainers:
   - At least one approval required
   - Address all review comments
   - Make requested changes

3. **Merge**:
   - Squash and merge for feature branches
   - Merge commit for releases
   - Delete branch after merge

### After Merge

- Update your fork:
  ```bash
  git checkout main
  git pull upstream main
  git push origin main
  ```

- Delete your feature branch:
  ```bash
  git branch -d feature/your-feature-name
  git push origin --delete feature/your-feature-name
  ```

## Specific Contribution Areas

### Adding a New Service

1. Create service directory: `services/new-service/`
2. Add docker-compose template: `docker-compose.yml.template`
3. Add configuration templates in `configs/`
4. Create service README: `services/new-service/README.md`
5. Update main `docker-compose.yml` to include service
6. Update template generation script
7. Add environment variables to `.env.example`
8. Update main README documentation
9. Add tests for new service

### Improving Documentation

- Update README files with clear examples
- Add troubleshooting sections
- Include screenshots/diagrams
- Fix typos and grammar
- Improve installation instructions

### Enhancing CI/CD

- Add new GitHub Actions workflows
- Improve test coverage
- Add security scanning tools
- Optimize build times
- Add deployment automation

### Fixing Bugs

1. Create issue describing bug
2. Create fix branch: `fix/bug-description`
3. Add test reproducing bug
4. Implement fix
5. Verify test passes
6. Submit PR referencing issue

## Getting Help

- **Documentation**: Check README.md and service-specific READMEs
- **Issues**: Search existing issues or create new one
- **Discussions**: Use GitHub Discussions for questions
- **Security**: Email security issues privately (see SECURITY.md)

## Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes (for significant contributions)
- Project documentation (for major features)

## License

By contributing to Carian Observatory, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to Carian Observatory! 🏰
