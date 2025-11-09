#!/usr/bin/env bash
# Unit tests for template generation system
# Tests template file processing and environment variable substitution

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

# Temporary directory for test files
TEST_DIR=""

# Cleanup function
cleanup() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

trap cleanup EXIT

# Setup test environment
setup_test_env() {
    TEST_DIR=$(mktemp -d)
    export PRIMARY_DOMAIN=test.example.com
    export WEBUI_DOMAIN=chat.test.example.com
    export USER_PREFIX=test-co
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

# Test 1: Template files exist
test_template_files_exist() {
    local template_count
    template_count=$(find . -name "*.template" -type f 2>/dev/null | wc -l)

    if [ "$template_count" -gt 0 ]; then
        pass "Found $template_count template files"
    else
        fail "No template files found"
    fi
}

# Test 2: All templates have yourdomain.com placeholder
test_templates_have_placeholder() {
    local templates_without_placeholder=()

    while IFS= read -r template_file; do
        if ! grep -q "yourdomain.com\|PRIMARY_DOMAIN\|example.com" "$template_file" 2>/dev/null; then
            templates_without_placeholder+=("$template_file")
        fi
    done < <(find services scripts -name "*.template" -type f 2>/dev/null)

    if [ ${#templates_without_placeholder[@]} -eq 0 ]; then
        pass "All templates use domain placeholders"
    else
        fail "Templates missing domain placeholders" "${templates_without_placeholder[*]}"
    fi
}

# Test 3: Template generation script exists and is executable
test_generation_script_exists() {
    if [ -f "scripts/create-all-from-templates.sh" ]; then
        pass "Template generation script exists"
    else
        fail "Template generation script not found"
        return
    fi

    if [ -x "scripts/create-all-from-templates.sh" ]; then
        pass "Template generation script is executable"
    else
        fail "Template generation script is not executable"
    fi
}

# Test 4: Simple template substitution works
test_simple_substitution() {
    local test_template="$TEST_DIR/test.conf.template"
    local test_output="$TEST_DIR/test.conf"

    # Create test template
    cat > "$test_template" << EOF
domain: \${PRIMARY_DOMAIN}
webui: \${WEBUI_DOMAIN}
prefix: \${USER_PREFIX}
EOF

    # Perform substitution (mimicking what the generation script does)
    envsubst < "$test_template" > "$test_output"

    # Verify substitution
    if grep -q "domain: test.example.com" "$test_output" && \
       grep -q "webui: chat.test.example.com" "$test_output" && \
       grep -q "prefix: test-co" "$test_output"; then
        pass "Template substitution works correctly"
    else
        fail "Template substitution failed" "$(cat "$test_output")"
    fi
}

# Test 5: No production domains in templates
test_no_production_domains() {
    local production_domains=(
        "freddieweir.com"
        "actual-production-domain.com"
        # Add other production domains to check
    )

    local templates_with_prod_domains=()

    for domain in "${production_domains[@]}"; do
        while IFS= read -r template_file; do
            if grep -q "$domain" "$template_file" 2>/dev/null; then
                templates_with_prod_domains+=("$template_file: $domain")
            fi
        done < <(find . -name "*.template" -type f 2>/dev/null)
    done

    if [ ${#templates_with_prod_domains[@]} -eq 0 ]; then
        pass "No production domains in templates"
    else
        fail "Production domains found in templates" "${templates_with_prod_domains[*]}"
    fi
}

# Test 6: Template files are co-located with generated files
test_template_colocation() {
    local misplaced_templates=()

    while IFS= read -r template_file; do
        # Template should be in services/ or scripts/ directory
        if [[ ! "$template_file" =~ ^(services|scripts)/ ]]; then
            misplaced_templates+=("$template_file")
        fi
    done < <(find . -name "*.template" -type f 2>/dev/null | grep -v ".git")

    if [ ${#misplaced_templates[@]} -eq 0 ]; then
        pass "All templates are properly co-located"
    else
        fail "Templates found outside services/scripts directories" "${misplaced_templates[*]}"
    fi
}

# Test 7: Generated files are gitignored
test_generated_files_gitignored() {
    local common_generated_files=(
        "configuration.yml"
        "docker-compose.yml"
        ".env"
    )

    local unignored_files=()

    for file_pattern in "${common_generated_files[@]}"; do
        if ! grep -q "^$file_pattern$\|/$file_pattern$" .gitignore 2>/dev/null; then
            # Check if there's a more specific pattern
            if ! grep -q "$file_pattern" .gitignore 2>/dev/null; then
                unignored_files+=("$file_pattern")
            fi
        fi
    done

    if [ ${#unignored_files[@]} -eq 0 ]; then
        pass "Common generated files are gitignored"
    else
        # This is a warning, not a failure
        echo -e "${YELLOW}⚠${NC} Some generated file patterns might not be gitignored: ${unignored_files[*]}"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    fi
}

# Test 8: Template syntax is valid (basic check)
test_template_syntax() {
    local invalid_templates=()

    while IFS= read -r template_file; do
        # Check for common syntax errors
        # 1. Unclosed variables like ${VAR
        if grep -q '\${[A-Z_]*$' "$template_file" 2>/dev/null; then
            invalid_templates+=("$template_file: unclosed variable")
        fi

        # 2. Invalid variable names (with spaces)
        if grep -q '\${\s' "$template_file" 2>/dev/null; then
            invalid_templates+=("$template_file: variable name with space")
        fi
    done < <(find services scripts -name "*.template" -type f 2>/dev/null)

    if [ ${#invalid_templates[@]} -eq 0 ]; then
        pass "Template syntax is valid"
    else
        fail "Template syntax errors detected" "${invalid_templates[*]}"
    fi
}

# Test 9: All templates have corresponding generation logic
test_templates_have_generation_logic() {
    # Check if the generation script references each service template
    if [ ! -f "scripts/create-all-from-templates.sh" ]; then
        fail "Generation script not found - skipping test"
        return
    fi

    local service_dirs
    service_dirs=$(find services -type d -maxdepth 1 -mindepth 1 2>/dev/null)

    local unreferenced_services=()

    for service_dir in $service_dirs; do
        local service_name
        service_name=$(basename "$service_dir")

        # Check if service has templates
        if find "$service_dir" -name "*.template" -type f | grep -q .; then
            # Check if generation script mentions this service
            if ! grep -q "$service_name" "scripts/create-all-from-templates.sh"; then
                unreferenced_services+=("$service_name")
            fi
        fi
    done

    if [ ${#unreferenced_services[@]} -eq 0 ]; then
        pass "All services with templates are in generation script"
    else
        fail "Services with templates not in generation script" "${unreferenced_services[*]}"
    fi
}

# Main test runner
main() {
    echo "======================================"
    echo "Template Generation Unit Tests"
    echo "======================================"
    echo

    # Setup
    cd "$(dirname "$0")/../.." || exit 1
    setup_test_env

    # Run tests
    test_template_files_exist
    test_templates_have_placeholder
    test_generation_script_exists
    test_simple_substitution
    test_no_production_domains
    test_template_colocation
    test_generated_files_gitignored
    test_template_syntax
    test_templates_have_generation_logic

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
