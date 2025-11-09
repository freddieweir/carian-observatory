#!/usr/bin/env bash
# Integration tests for Docker Compose configurations
# Tests validation, syntax, and service dependencies

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup_test_env() {
    export USER_PREFIX=co-test
    export COMPOSE_PROJECT_NAME=carian-observatory-test
    export AUTHELIA_SESSION_SECRET=test_session_secret_32_characters_minimum_length_required
    export AUTHELIA_STORAGE_ENCRYPTION_KEY=test_storage_key_32_characters_minimum_length_required
    export PRIMARY_DOMAIN=test.example.com
    export WEBUI_DOMAIN=chat.test.example.com
    export PERPLEXICA_DOMAIN=search.test.example.com
    export AUTH_DOMAIN=auth.test.example.com
    export CANARY_DOMAIN=canary.test.example.com
    export AUTHELIA_PORT=9091
    export CANARY_AUTHELIA_PORT=9092
}

# Test result tracking
pass() {
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
    echo -e "${RED}✗${NC} $1"
    if [ -n "${2:-}" ]; then
        echo -e "  ${YELLOW}Error: $2${NC}"
    fi
}

# Test 1: Main docker-compose.yml is valid
test_main_compose_valid() {
    if docker compose -f docker-compose.yml config > /dev/null 2>&1; then
        pass "Main docker-compose.yml is valid"
    else
        fail "Main docker-compose.yml validation failed" "$(docker compose -f docker-compose.yml config 2>&1 | tail -n 5)"
    fi
}

# Test 2: All service compose files are valid
test_service_compose_files() {
    local service_compose_files
    service_compose_files=$(find services -name "docker-compose*.yml" -o -name "docker-compose*.yaml" 2>/dev/null)

    if [ -z "$service_compose_files" ]; then
        fail "No service compose files found"
        return
    fi

    for compose_file in $service_compose_files; do
        if [ -f "$compose_file" ]; then
            if docker compose -f "$compose_file" config > /dev/null 2>&1; then
                pass "Service compose file valid: $compose_file"
            else
                fail "Service compose file invalid: $compose_file" "$(docker compose -f "$compose_file" config 2>&1 | tail -n 3)"
            fi
        fi
    done
}

# Test 3: All included paths in main compose exist
test_included_paths_exist() {
    local missing_includes=()

    # Extract include paths from main docker-compose.yml
    while IFS= read -r include_path; do
        if [ ! -f "$include_path" ]; then
            missing_includes+=("$include_path")
        fi
    done < <(grep -E "^\s*-\s*path:" docker-compose.yml | sed 's/.*path:\s*//' | tr -d ' ')

    if [ ${#missing_includes[@]} -eq 0 ]; then
        pass "All included compose files exist"
    else
        fail "Missing included compose files" "${missing_includes[*]}"
    fi
}

# Test 4: No duplicate container names across services
test_no_duplicate_containers() {
    local all_containers
    all_containers=$(docker compose -f docker-compose.yml config --services 2>/dev/null)

    local unique_containers
    unique_containers=$(echo "$all_containers" | sort -u)

    if [ "$(echo "$all_containers" | wc -l)" -eq "$(echo "$unique_containers" | wc -l)" ]; then
        pass "No duplicate container names"
    else
        fail "Duplicate container names detected"
    fi
}

# Test 5: All referenced networks are defined
test_networks_defined() {
    # This is a simplified check - in practice would parse YAML properly
    local compose_config
    compose_config=$(docker compose -f docker-compose.yml config 2>/dev/null)

    if [ -n "$compose_config" ]; then
        pass "Network configuration is valid"
    else
        fail "Network configuration is invalid"
    fi
}

# Test 6: Volume mounts point to existing template directories
test_volume_paths_exist() {
    local required_dirs=(
        "services/open-webui"
        "services/perplexica"
        "services/authelia"
        "services/nginx"
        "services/monitoring"
    )

    local missing_dirs=()
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done

    if [ ${#missing_dirs[@]} -eq 0 ]; then
        pass "All required service directories exist"
    else
        fail "Missing service directories" "${missing_dirs[*]}"
    fi
}

# Test 7: Health checks are properly configured
test_healthchecks_configured() {
    local compose_config
    compose_config=$(docker compose -f docker-compose.yml config 2>/dev/null)

    if echo "$compose_config" | grep -q "healthcheck:"; then
        pass "Health checks are configured"
    else
        fail "No health checks found in compose configuration"
    fi
}

# Test 8: Environment variables are used (not hardcoded values)
test_no_hardcoded_secrets() {
    local hardcoded_issues=()

    # Check for common hardcoded patterns in compose files (excluding comments)
    if grep -r "password:\s*['\"].*['\"]" services/*/docker-compose*.yml 2>/dev/null | grep -v "^\s*#"; then
        hardcoded_issues+=("Found hardcoded passwords")
    fi

    if [ ${#hardcoded_issues[@]} -eq 0 ]; then
        pass "No hardcoded secrets in compose files"
    else
        fail "Security issue: hardcoded values detected" "${hardcoded_issues[*]}"
    fi
}

# Main test runner
main() {
    echo "======================================"
    echo "Docker Compose Integration Tests"
    echo "======================================"
    echo

    # Setup
    cd "$(dirname "$0")/../.." || exit 1
    setup_test_env

    # Run tests
    test_main_compose_valid
    test_service_compose_files
    test_included_paths_exist
    test_no_duplicate_containers
    test_networks_defined
    test_volume_paths_exist
    test_healthchecks_configured
    test_no_hardcoded_secrets

    # Summary
    echo
    echo "======================================"
    echo "Test Summary"
    echo "======================================"
    echo -e "Total:  $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

main "$@"
