#!/bin/bash
# Generate Prometheus configuration files from templates
# Uses environment variables from .env file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Prometheus Config Generator"
echo "=========================================="
echo ""

# Load environment variables from .env
if [ -f "$REPO_ROOT/.env" ]; then
    echo -e "${GREEN}✓${NC} Loading environment variables from .env"
    # Export variables for envsubst
    set -a
    source "$REPO_ROOT/.env"
    set +a
else
    echo -e "${YELLOW}⚠${NC}  .env file not found at $REPO_ROOT/.env"
    echo "   Continuing with system environment variables..."
fi

# Generate prometheus.yml
echo ""
echo -e "${GREEN}→${NC} Generating prometheus.yml from template..."
if [ -f "$SCRIPT_DIR/prometheus.yml.template" ]; then
    envsubst < "$SCRIPT_DIR/prometheus.yml.template" > "$SCRIPT_DIR/prometheus.yml"
    echo -e "${GREEN}✓${NC} Generated: prometheus.yml"
else
    echo -e "${RED}✗${NC} Template not found: prometheus.yml.template"
    exit 1
fi

# Generate alerts.yml
echo -e "${GREEN}→${NC} Generating alerts.yml from template..."
if [ -f "$SCRIPT_DIR/alerts.yml.template" ]; then
    envsubst < "$SCRIPT_DIR/alerts.yml.template" > "$SCRIPT_DIR/alerts.yml"
    echo -e "${GREEN}✓${NC} Generated: alerts.yml"
else
    echo -e "${RED}✗${NC} Template not found: alerts.yml.template"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓${NC} Configuration generation complete"
echo "=========================================="
echo ""
echo "Generated files:"
echo "  - services/monitoring/prometheus/prometheus.yml"
echo "  - services/monitoring/prometheus/alerts.yml"
echo ""
echo "To apply changes, restart Prometheus:"
echo "  docker restart co-monitoring-prometheus"
echo ""
