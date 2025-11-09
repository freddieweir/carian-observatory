# Carian Observatory Test Suite

Automated tests for validating Docker Compose configurations, template generation, and infrastructure components.

## Test Structure

```
tests/
├── integration/          # Integration tests (services working together)
│   └── test_docker_compose.sh
├── unit/                # Unit tests (individual components)
│   └── test_template_generation.sh
├── run_all_tests.sh     # Master test runner
└── README.md           # This file
```

## Running Tests

### Run All Tests

```bash
./tests/run_all_tests.sh
```

### Run Specific Test Suite

```bash
# Unit tests only
./tests/unit/test_template_generation.sh

# Integration tests only
./tests/integration/test_docker_compose.sh
```

## Test Suites

### Integration Tests

#### `test_docker_compose.sh`
Tests Docker Compose configuration validity and service integration:

- ✅ Main docker-compose.yml validation
- ✅ Individual service compose file validation
- ✅ Include path verification
- ✅ Container name uniqueness
- ✅ Network configuration
- ✅ Volume mount path existence
- ✅ Health check configuration
- ✅ Security: No hardcoded secrets

**Requirements**: Docker and Docker Compose installed

**Example**:
```bash
cd /path/to/carian-observatory
./tests/integration/test_docker_compose.sh
```

### Unit Tests

#### `test_template_generation.sh`
Tests template file system and generation logic:

- ✅ Template file existence
- ✅ Domain placeholder usage (yourdomain.com)
- ✅ Generation script availability
- ✅ Variable substitution correctness
- ✅ No production domains in templates
- ✅ Template co-location with generated files
- ✅ Generated files in .gitignore
- ✅ Template syntax validation
- ✅ Generation script coverage

**Requirements**: Bash 4.0+, envsubst

**Example**:
```bash
./tests/unit/test_template_generation.sh
```

## CI Integration

Tests are automatically run in GitHub Actions via:
- `.github/workflows/ci-build-test.yml` - Infrastructure validation workflow

The CI workflow runs:
1. Docker Compose validation
2. ShellCheck linting
3. YAML validation
4. Template generation testing
5. Security checks

## Adding New Tests

### Adding a Unit Test

1. Create test file in `tests/unit/`:
   ```bash
   touch tests/unit/test_new_feature.sh
   chmod +x tests/unit/test_new_feature.sh
   ```

2. Use the template structure:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   # Test counters
   TESTS_RUN=0
   TESTS_PASSED=0
   TESTS_FAILED=0

   pass() {
       ((TESTS_PASSED++))
       ((TESTS_RUN++))
       echo "✓ $1"
   }

   fail() {
       ((TESTS_FAILED++))
       ((TESTS_RUN++))
       echo "✗ $1"
   }

   # Your tests here
   test_something() {
       if [ condition ]; then
           pass "Test description"
       else
           fail "Test description"
       fi
   }

   # Main
   cd "$(dirname "$0")/../.."
   test_something

   # Exit with appropriate code
   [ $TESTS_FAILED -eq 0 ]
   ```

3. Run: `./tests/run_all_tests.sh`

### Adding an Integration Test

Follow the same process but place in `tests/integration/` and ensure tests verify cross-service functionality.

## Test Requirements

### Environment Variables

Tests use safe defaults. For custom testing, set:

```bash
export PRIMARY_DOMAIN=test.example.com
export WEBUI_DOMAIN=chat.test.example.com
export PERPLEXICA_DOMAIN=search.test.example.com
export AUTH_DOMAIN=auth.test.example.com
export USER_PREFIX=co-test
export COMPOSE_PROJECT_NAME=carian-observatory-test
export AUTHELIA_SESSION_SECRET=test_secret_32_chars_minimum_len
export AUTHELIA_STORAGE_ENCRYPTION_KEY=test_key_32_chars_minimum_length
```

### Dependencies

**Required**:
- Bash 4.0+
- Docker 20.10+
- Docker Compose 2.20+

**Optional** (for enhanced testing):
- `shellcheck` - Shell script linting
- `yamllint` - YAML validation
- `envsubst` - Environment variable substitution

**Install on Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install -y shellcheck yamllint gettext-base
```

**Install on macOS**:
```bash
brew install shellcheck yamllint gettext
```

## Test Output

### Successful Run
```
======================================
Template Generation Unit Tests
======================================

✓ Found 38 template files
✓ All templates use domain placeholders
✓ Template generation script exists
✓ Template generation script is executable
✓ Template substitution works correctly
✓ No production domains in templates
✓ All templates are properly co-located
✓ Common generated files are gitignored
✓ Template syntax is valid
✓ All services with templates are in generation script

======================================
Test Summary
======================================
Total:  10
Passed: 10
All tests passed!
```

### Failed Run
```
======================================
Docker Compose Integration Tests
======================================

✓ Main docker-compose.yml is valid
✗ Service compose file invalid: services/broken/docker-compose.yml
  Error: yaml: line 15: mapping values are not allowed here
✓ All included compose files exist

======================================
Test Summary
======================================
Total:  3
Passed: 2
Failed: 1
```

## Continuous Integration

### GitHub Actions

Tests run automatically on:
- Push to main/master/develop branches
- Pull requests
- Manual workflow dispatch

View results:
```
https://github.com/freddieweir/carian-observatory/actions
```

### Pre-commit Hooks

To run tests before committing:

```bash
# Add to .git/hooks/pre-commit
#!/bin/bash
./tests/run_all_tests.sh
```

## Troubleshooting

### Docker Compose validation fails

**Issue**: `docker compose config` errors

**Solution**:
1. Ensure all environment variables are set
2. Check template files were generated: `./scripts/create-all-from-templates.sh`
3. Verify .env file exists with required values

### Template substitution fails

**Issue**: Variables not replaced in generated files

**Solution**:
1. Check `envsubst` is installed: `which envsubst`
2. Verify environment variables are exported: `export VAR=value`
3. Ensure template uses `${VAR}` syntax (with braces)

### Tests fail in CI but pass locally

**Issue**: Environment differences

**Solution**:
1. Check CI logs for specific error messages
2. Verify all dependencies are in CI workflow
3. Ensure tests don't depend on local files/state
4. Add `set -x` to test script for verbose debugging

## Test Coverage

Current coverage:

| Component | Unit Tests | Integration Tests | Coverage |
|-----------|-----------|------------------|----------|
| Docker Compose | ❌ | ✅ | 80% |
| Templates | ✅ | ❌ | 90% |
| Shell Scripts | ⚠️ (via CI) | ❌ | 60% |
| Nginx Config | ❌ | ❌ | 0% |
| Security | ⚠️ (via CI) | ❌ | 50% |

**Legend**: ✅ Covered | ⚠️ Partial | ❌ Not Covered

## Future Improvements

- [ ] Add nginx configuration validation tests
- [ ] Test SSL/TLS certificate handling
- [ ] Add service-specific health check tests
- [ ] Test backup/restore procedures
- [ ] Add performance/load testing
- [ ] Test monitoring alert rules
- [ ] Validate Prometheus/Grafana configs
- [ ] Test Authelia authentication flows
- [ ] Add security scanning integration
- [ ] Test disaster recovery procedures

## Contributing

When adding features:
1. Write tests first (TDD approach)
2. Ensure tests pass locally
3. Run full test suite before committing
4. Add test documentation to this README

## Support

For issues with tests:
1. Check this README first
2. Review test output carefully
3. Check GitHub Actions logs
4. Open issue with test output attached

## License

Tests are part of the Carian Observatory project and follow the same license.
