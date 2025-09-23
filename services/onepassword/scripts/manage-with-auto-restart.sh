#!/bin/bash
# Enhanced 1Password Connect Manager with Auto-Restart
# Combines manual management with automatic Touch ID restart capabilities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_FILE="/tmp/1password-credentials.json"
PLIST_NAME="com.carian-observatory.onepassword-connect"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show usage
usage() {
    echo -e "${CYAN}1Password Connect Manager with Auto-Restart${NC}"
    echo -e "${YELLOW}Usage: $0 {start|stop|restart|status|logs|health|auto-install|auto-remove}${NC}"
    echo ""
    echo "Manual Commands:"
    echo "  start    - Start 1Password Connect with Touch ID authentication"
    echo "  stop     - Stop 1Password Connect and clean up credentials"
    echo "  restart  - Restart services with fresh Touch ID authentication"
    echo "  status   - Show current service status"
    echo "  logs     - Show recent logs from both services"
    echo "  health   - Check API health endpoint"
    echo ""
    echo "Auto-Restart Commands:"
    echo "  auto-install - Install auto-restart monitor (Launch Agent)"
    echo "  auto-remove  - Remove auto-restart monitor"
    echo "  auto-status  - Show auto-restart monitor status"
    echo ""
    echo "Auto-Restart Features:"
    echo "  • Monitors container health continuously"
    echo "  • Automatically prompts for Touch ID when containers fail"
    echo "  • Runs as background macOS Launch Agent"
    echo "  • Survives system reboots and user logouts"
    exit 1
}

# Auto-restart functions
install_auto_restart() {
    echo -e "${BLUE}Installing Auto-Restart Monitor${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"

    if [ -f "$PLIST_PATH" ]; then
        echo -e "${YELLOW}Launch Agent already exists. Updating...${NC}"
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
    fi

    "$SCRIPT_DIR/install-launch-agent.sh"

    echo -e "\n${GREEN}✓ Auto-restart monitoring is now active${NC}"
    echo -e "${YELLOW}The system will automatically prompt for Touch ID when 1Password Connect needs to restart.${NC}"
}

remove_auto_restart() {
    echo -e "${YELLOW}Removing Auto-Restart Monitor${NC}"

    if [ -f "$PLIST_PATH" ]; then
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
        rm -f "$PLIST_PATH"
        echo -e "${GREEN}✓ Launch Agent removed${NC}"
    else
        echo -e "${YELLOW}No Launch Agent found${NC}"
    fi

    # Stop background monitor if running
    "$SCRIPT_DIR/auto-restart-monitor.sh" stop 2>/dev/null || true
}

show_auto_status() {
    echo -e "${CYAN}Auto-Restart Monitor Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    # Check Launch Agent
    echo -e "\n${YELLOW}Launch Agent:${NC}"
    if [ -f "$PLIST_PATH" ]; then
        echo -e "${GREEN}✓ Launch Agent installed${NC}"
        if launchctl list | grep -q "$PLIST_NAME"; then
            echo -e "${GREEN}✓ Launch Agent is running${NC}"
        else
            echo -e "${RED}✗ Launch Agent is not running${NC}"
        fi
    else
        echo -e "${RED}✗ Launch Agent not installed${NC}"
    fi

    # Check background monitor
    echo -e "\n${YELLOW}Background Monitor:${NC}"
    "$SCRIPT_DIR/auto-restart-monitor.sh" status

    # Show recent auto-restart logs
    echo -e "\n${YELLOW}Recent Auto-Restart Activity:${NC}"
    if [ -f "/tmp/1password-connect-agent.log" ]; then
        tail -5 "/tmp/1password-connect-agent.log" 2>/dev/null || echo "No recent activity"
    else
        echo "No logs found"
    fi
}

# Enhanced start function with auto-restart option
start_with_auto() {
    echo -e "${BLUE}Starting 1Password Connect${NC}"

    # Start the services normally
    "$SCRIPT_DIR/manage-1password-connect.sh" start

    # Ask if user wants auto-restart
    echo -e "\n${YELLOW}Would you like to enable auto-restart monitoring? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        install_auto_restart
    fi
}

# Enhanced stop function
stop_with_cleanup() {
    echo -e "${YELLOW}Stopping 1Password Connect${NC}"

    # Stop services
    "$SCRIPT_DIR/manage-1password-connect.sh" stop

    # Ask about auto-restart monitor
    if [ -f "$PLIST_PATH" ]; then
        echo -e "\n${YELLOW}Auto-restart monitor is still active. Keep it running? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Nn] ]]; then
            remove_auto_restart
        fi
    fi
}

# Main script logic
case "${1:-}" in
    start)
        start_with_auto
        ;;
    stop)
        stop_with_cleanup
        ;;
    restart)
        "$SCRIPT_DIR/manage-1password-connect.sh" restart
        ;;
    status)
        "$SCRIPT_DIR/manage-1password-connect.sh" status
        echo ""
        show_auto_status
        ;;
    logs)
        "$SCRIPT_DIR/manage-1password-connect.sh" logs
        ;;
    health)
        "$SCRIPT_DIR/manage-1password-connect.sh" health
        ;;
    auto-install)
        install_auto_restart
        ;;
    auto-remove)
        remove_auto_restart
        ;;
    auto-status)
        show_auto_status
        ;;
    *)
        usage
        ;;
esac