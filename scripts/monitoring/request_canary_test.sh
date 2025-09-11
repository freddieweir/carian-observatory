#!/bin/bash

# ============================================================================
# Production Claude - Request Canary Testing
# ============================================================================
# Sends deployment request to Canary for testing

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
COMM_DIR="/Volumes/aetherium/Shared Parallel/macOS Dev Files/Claude Communication"
LOG_FILE="$COMM_DIR/communication_log.txt"

# Function to display menu
show_menu() {
    echo -e "\n${BLUE}${BOLD}=== Request Canary Testing ===${NC}"
    echo "1) Test current configuration"
    echo "2) Test authentication changes"
    echo "3) Test service update"
    echo "4) Test full deployment"
    echo "5) Request canary status"
    echo "6) Send custom message"
    echo "7) Exit"
    echo -n "Select option: "
}

# Function to send request
send_request() {
    local message="$1"
    echo "[PRODUCTION] $(date '+%Y-%m-%d %H:%M:%S') - REQUEST: $message" >> "$LOG_FILE"
    echo -e "${GREEN}✓ Request sent to Canary${NC}"
    echo -e "${YELLOW}Monitor canary response with: ./scripts/monitor_canary.sh${NC}"
}

# Get current git status for deployment info
get_deployment_info() {
    local branch=$(git branch --show-current)
    local commit=$(git rev-parse --short HEAD)
    local changes=$(git status --porcelain | wc -l | tr -d ' ')
    echo "branch=$branch commit=$commit changes=$changes"
}

# Main loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            echo -e "${YELLOW}Requesting configuration test...${NC}"
            send_request "TEST_DEPLOYMENT type=config $(get_deployment_info)"
            ;;
        2)
            echo -e "${YELLOW}Requesting authentication test...${NC}"
            # Check current auth policy
            AUTH_POLICY=$(grep "policy:" configs/authelia/configuration.yml | head -1 | awk '{print $3}' | tr -d "'")
            send_request "TEST_DEPLOYMENT type=auth policy=$AUTH_POLICY $(get_deployment_info)"
            ;;
        3)
            echo -e "${YELLOW}Which service to test?${NC}"
            echo "1) Authelia"
            echo "2) Perplexica"
            echo "3) WebUI"
            echo "4) Nginx"
            read -r service_choice
            
            case $service_choice in
                1) SERVICE="authelia" ;;
                2) SERVICE="perplexica" ;;
                3) SERVICE="webui" ;;
                4) SERVICE="nginx" ;;
                *) SERVICE="unknown" ;;
            esac
            
            send_request "TEST_DEPLOYMENT type=service service=$SERVICE $(get_deployment_info)"
            ;;
        4)
            echo -e "${YELLOW}Requesting full deployment test...${NC}"
            echo -e "${RED}This will test all services and configurations${NC}"
            echo -n "Continue? (y/n): "
            read -r confirm
            
            if [ "$confirm" = "y" ]; then
                send_request "TEST_DEPLOYMENT type=full $(get_deployment_info)"
            fi
            ;;
        5)
            echo -e "${YELLOW}Requesting canary status...${NC}"
            send_request "STATUS_CHECK"
            ;;
        6)
            echo -n "Enter message for Canary: "
            read -r custom_message
            send_request "$custom_message"
            ;;
        7)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    # Show recent canary responses
    echo -e "\n${BLUE}Recent Canary responses:${NC}"
    grep "\[CANARY\]" "$LOG_FILE" | tail -5
done