#!/bin/bash
# 1Password Connect Service Manager with Touch ID Authentication
# Provides start, stop, restart, and status commands with secure credential handling

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_FILE="/tmp/1password-credentials.json"
PID_FILE="/tmp/1password-connect.pid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show usage
usage() {
    echo -e "${CYAN}1Password Connect Service Manager${NC}"
    echo -e "${YELLOW}Usage: $0 {start|stop|restart|status|logs|health}${NC}"
    echo ""
    echo "Commands:"
    echo "  start    - Start 1Password Connect with Touch ID authentication"
    echo "  stop     - Stop 1Password Connect and clean up credentials"
    echo "  restart  - Restart services with fresh Touch ID authentication"
    echo "  status   - Show current service status"
    echo "  logs     - Show recent logs from both services"
    echo "  health   - Check API health endpoint"
    echo ""
    echo "Security:"
    echo "  • Credentials are fetched from 1Password using Touch ID"
    echo "  • Credentials are stored in memory (tmpfs) only"
    echo "  • Credentials are securely shredded on stop"
    exit 1
}

# Start services
start_services() {
    echo -e "${BLUE}Starting 1Password Connect with Touch ID...${NC}"

    # Check if already running
    if docker ps --format '{{.Names}}' | grep -q "co-1p-connect"; then
        echo -e "${YELLOW}⚠ 1Password Connect is already running${NC}"
        return 0
    fi

    # Start with Touch ID
    "$SCRIPT_DIR/start-with-touchid.sh"
}

# Stop services
stop_services() {
    echo -e "${YELLOW}Stopping 1Password Connect...${NC}"

    cd "$SERVICE_DIR"
    docker compose down

    # Clean up credentials if they exist
    if [ -f "$CREDENTIALS_FILE" ]; then
        echo -e "${YELLOW}Securely removing credentials...${NC}"
        shred -u "$CREDENTIALS_FILE" 2>/dev/null || rm -f "$CREDENTIALS_FILE"
        echo -e "${GREEN}✓ Credentials removed${NC}"
    fi

    # Clean up override file if it exists
    rm -f "$SERVICE_DIR/docker-compose.override.yml"

    echo -e "${GREEN}✓ 1Password Connect stopped${NC}"
}

# Restart services
restart_services() {
    echo -e "${BLUE}Restarting 1Password Connect...${NC}"
    stop_services
    sleep 2
    start_services
}

# Show status
show_status() {
    echo -e "${CYAN}1Password Connect Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    # Check container status
    echo -e "\n${YELLOW}Container Status:${NC}"
    docker ps --filter "name=co-1p-connect" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    # Check credentials file
    echo -e "\n${YELLOW}Credentials:${NC}"
    if [ -f "$CREDENTIALS_FILE" ]; then
        echo -e "${GREEN}✓ Credentials file present (in memory)${NC}"
        ls -lh "$CREDENTIALS_FILE" | awk '{print "  Size: "$5", Permissions: "$1}'
    else
        echo -e "${RED}✗ No credentials file found${NC}"
    fi

    # Check API health
    echo -e "\n${YELLOW}API Health:${NC}"
    if curl -sf http://localhost:8090/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API is healthy${NC}"
        curl -s http://localhost:8090/health | jq '.'
    else
        echo -e "${RED}✗ API is not responding${NC}"
    fi
}

# Show logs
show_logs() {
    echo -e "${CYAN}1Password Connect Logs${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    echo -e "\n${YELLOW}Sync Service Logs:${NC}"
    docker logs co-1p-connect-sync --tail 20

    echo -e "\n${YELLOW}API Service Logs:${NC}"
    docker logs co-1p-connect-api --tail 20
}

# Check health
check_health() {
    echo -e "${CYAN}Checking 1Password Connect Health${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    echo -e "\n${YELLOW}API Health Endpoint:${NC}"
    if response=$(curl -sf http://localhost:8090/health 2>&1); then
        echo -e "${GREEN}✓ API is healthy${NC}"
        echo "$response" | jq '.'
    else
        echo -e "${RED}✗ API health check failed${NC}"
        echo "Error: $response"
        exit 1
    fi

    echo -e "\n${YELLOW}Container Health:${NC}"
    docker inspect co-1p-connect-sync --format '{{.State.Health.Status}}' | xargs echo "Sync Service:"
    docker inspect co-1p-connect-api --format '{{.State.Health.Status}}' | xargs echo "API Service:"
}

# Main script logic
case "${1:-}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    health)
        check_health
        ;;
    *)
        usage
        ;;
esac