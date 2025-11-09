#!/usr/bin/env bash
# Master test runner for all Carian Observatory tests
# Runs unit tests and integration tests

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test suite tracking
SUITES_RUN=0
SUITES_PASSED=0
SUITES_FAILED=0

# Change to repository root
cd "$(dirname "$0")/.." || exit 1

echo "=========================================="
echo "Carian Observatory Test Suite"
echo "=========================================="
echo

# Make all test scripts executable
chmod +x tests/unit/*.sh 2>/dev/null || true
chmod +x tests/integration/*.sh 2>/dev/null || true

# Run unit tests
echo -e "${BLUE}>>> Running Unit Tests${NC}"
echo "=========================================="
for test_file in tests/unit/*.sh; do
    if [ -f "$test_file" ]; then
        ((SUITES_RUN++))
        echo
        echo -e "${BLUE}Running: $(basename "$test_file")${NC}"
        if bash "$test_file"; then
            ((SUITES_PASSED++))
        else
            ((SUITES_FAILED++))
            echo -e "${RED}Test suite failed: $test_file${NC}"
        fi
    fi
done

echo
echo

# Run integration tests
echo -e "${BLUE}>>> Running Integration Tests${NC}"
echo "=========================================="
for test_file in tests/integration/*.sh; do
    if [ -f "$test_file" ]; then
        ((SUITES_RUN++))
        echo
        echo -e "${BLUE}Running: $(basename "$test_file")${NC}"
        if bash "$test_file"; then
            ((SUITES_PASSED++))
        else
            ((SUITES_FAILED++))
            echo -e "${RED}Test suite failed: $test_file${NC}"
        fi
    fi
done

# Final summary
echo
echo "=========================================="
echo "Final Test Summary"
echo "=========================================="
echo -e "Test Suites Run:    $SUITES_RUN"
echo -e "${GREEN}Test Suites Passed: $SUITES_PASSED${NC}"

if [ $SUITES_FAILED -gt 0 ]; then
    echo -e "${RED}Test Suites Failed: $SUITES_FAILED${NC}"
    echo
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}Test Suites Failed: 0${NC}"
    echo
    echo -e "${GREEN}✅ All test suites passed!${NC}"
    exit 0
fi
