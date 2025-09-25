#!/bin/bash

# Script to update IP addresses in /etc/hosts for Carian Observatory domains
# Useful when your home IP changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default old IP (will be auto-detected from /etc/hosts if not specified)
DEFAULT_OLD_IP=""
OLD_IP=""
NEW_IP=""

# List of Carian Observatory domains
DOMAINS=(
    "auth.corporateseas.com"
    "webui.corporateseas.com"
    "perplexica.corporateseas.com"
    "homepage.corporateseas.com"
    "glance.corporateseas.com"
    "monitoring.corporateseas.com"
    "webui-canary.corporateseas.com"
)

# Function to detect old IP from /etc/hosts
detect_old_ip() {
    # Look for any of our domains in /etc/hosts and get the IP
    for domain in "${DOMAINS[@]}"; do
        if grep -q "$domain" /etc/hosts; then
            local detected_ip=$(grep "$domain" /etc/hosts | awk '{print $1}' | head -1)
            echo "$detected_ip"
            return
        fi
    done
    # If no domains found, return empty
    echo ""
}

# Function to show usage
usage() {
    echo "Usage: $0 [OLD_IP] NEW_IP"
    echo ""
    echo "Updates all Carian Observatory domains in /etc/hosts from OLD_IP to NEW_IP"
    echo ""
    echo "Arguments:"
    echo "  OLD_IP  - The old IP address to replace (auto-detected from /etc/hosts if not specified)"
    echo "  NEW_IP  - The new IP address to use (required)"
    echo ""
    echo "Special commands:"
    echo "  auto    - Auto-detect both old IP and current machine IP (prioritizes local network)"
    echo "  list    - Show all available network IPs on this machine"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.100                     # Auto-detect old IP and replace with 192.168.1.100"
    echo "  $0 192.168.5.28 192.168.1.100        # Replace specific IP"
    echo "  $0 auto                              # Auto-detect both IPs (prefers 192.168.x.x)"
    echo "  $0 list                              # Show all available IPs to choose from"
    exit 1
}

# Function to list all IPs
list_all_ips() {
    echo -e "${BLUE}=== Available Network IPs ===${NC}"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo -e "${GREEN}Local Network IPs (192.168.x.x):${NC}"
        ifconfig | grep "inet " | grep -E "192\.168\.[0-9]+\.[0-9]+" | awk '{print "  " $2}'

        echo -e "\n${GREEN}Other Private IPs (10.x.x.x):${NC}"
        ifconfig | grep "inet " | grep -E "10\.[0-9]+\.[0-9]+\.[0-9]+" | awk '{print "  " $2}'

        echo -e "\n${GREEN}Other Private IPs (172.16-31.x.x):${NC}"
        ifconfig | grep "inet " | grep -E "172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]+\.[0-9]+" | awk '{print "  " $2}'

        echo -e "\n${YELLOW}Other IPs (possibly VPN or public):${NC}"
        ifconfig | grep "inet " | grep -v -E "(127\.0\.0\.1|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" | awk '{print "  " $2}'
    else
        # Linux
        ip -4 addr | grep inet | awk '{print "  " $2}' | cut -d/ -f1
    fi
    echo ""
    echo -e "${BLUE}Tip: Use the most appropriate IP for your current network location${NC}"
    exit 0
}

# Function to get current machine IP
get_current_ip() {
    # Try to get IP from active network interface
    # Prioritize local network addresses (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - get IP from primary interface, prioritizing local networks
        # First try to find 192.168.x.x addresses
        IP=$(ifconfig | grep "inet " | grep -E "192\.168\.[0-9]+\.[0-9]+" | head -1 | awk '{print $2}')

        # If not found, try 10.x.x.x addresses
        if [ -z "$IP" ]; then
            IP=$(ifconfig | grep "inet " | grep -E "10\.[0-9]+\.[0-9]+\.[0-9]+" | head -1 | awk '{print $2}')
        fi

        # If not found, try 172.16-31.x.x addresses
        if [ -z "$IP" ]; then
            IP=$(ifconfig | grep "inet " | grep -E "172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]+\.[0-9]+" | head -1 | awk '{print $2}')
        fi

        # Last resort - any non-localhost IP (might be VPN)
        if [ -z "$IP" ]; then
            IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
            echo -e "${YELLOW}Warning: Using non-local IP (possibly VPN): $IP${NC}" >&2
        fi
    else
        # Linux - get IP from primary interface
        IP=$(ip route get 1 | awk '{print $NF;exit}')
    fi

    if [ -z "$IP" ]; then
        echo -e "${RED}Error: Could not auto-detect IP address${NC}"
        exit 1
    fi

    echo "$IP"
}

# Check arguments
if [ "$#" -eq 0 ]; then
    usage
fi

# Handle special commands
if [ "$1" == "list" ]; then
    list_all_ips
fi

# Handle auto mode
if [ "$1" == "auto" ]; then
    OLD_IP=$(detect_old_ip)
    if [ -z "$OLD_IP" ]; then
        echo -e "${RED}Error: No Carian Observatory domains found in /etc/hosts${NC}"
        exit 1
    fi
    NEW_IP=$(get_current_ip)
    echo -e "${GREEN}Auto-detected old IP: ${YELLOW}$OLD_IP${NC}"
    echo -e "${GREEN}Auto-detected new IP: ${BLUE}$NEW_IP${NC}"
elif [ "$#" -eq 1 ]; then
    NEW_IP="$1"
    OLD_IP=$(detect_old_ip)
    if [ -z "$OLD_IP" ]; then
        echo -e "${RED}Error: No Carian Observatory domains found in /etc/hosts${NC}"
        echo -e "${YELLOW}Please specify both old and new IP addresses${NC}"
        exit 1
    fi
    echo -e "${GREEN}Auto-detected old IP: ${YELLOW}$OLD_IP${NC}"
elif [ "$#" -eq 2 ]; then
    OLD_IP="$1"
    NEW_IP="$2"
else
    usage
fi

# Validate IP format (basic check)
validate_ip() {
    local ip=$1
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}Error: Invalid IP format: $ip${NC}"
        exit 1
    fi
}

validate_ip "$OLD_IP"
validate_ip "$NEW_IP"

echo -e "${BLUE}=== Carian Observatory /etc/hosts IP Update ===${NC}"
echo -e "Replacing: ${YELLOW}$OLD_IP${NC} → ${GREEN}$NEW_IP${NC}"
echo ""

# Check if we need sudo
if [ ! -w /etc/hosts ]; then
    echo -e "${YELLOW}Note: This script requires sudo access to modify /etc/hosts${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

# Create backup of /etc/hosts
BACKUP_FILE="/tmp/hosts.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${BLUE}Creating backup: ${BACKUP_FILE}${NC}"
cp /etc/hosts "$BACKUP_FILE"

# Check current state
echo -e "\n${BLUE}Current entries with $OLD_IP:${NC}"
grep "$OLD_IP" /etc/hosts | grep -E "$(IFS='|'; echo "${DOMAINS[*]}")" || echo "  (none found)"

# Prepare sed command
SED_CMD="s/^$OLD_IP\(\s\+\)/\$NEW_IP\1/g"

# Update /etc/hosts
echo -e "\n${BLUE}Updating /etc/hosts...${NC}"
TEMP_FILE="/tmp/hosts.new.$$"

# Process the file (need to read with appropriate permissions)
# Note: Using space and tab pattern for compatibility with macOS sed
if [ -n "$SUDO" ]; then
    $SUDO cat /etc/hosts | sed "s/^$OLD_IP[[:space:]]/$NEW_IP /g" > "$TEMP_FILE"
else
    sed "s/^$OLD_IP[[:space:]]/$NEW_IP /g" /etc/hosts > "$TEMP_FILE"
fi

# Check if changes were made
if diff -q /etc/hosts "$TEMP_FILE" > /dev/null 2>&1; then
    echo -e "${YELLOW}No changes needed - $OLD_IP not found in /etc/hosts${NC}"
    rm -f "$TEMP_FILE"

    # Check if domains exist with different IP
    echo -e "\n${BLUE}Checking for domains with other IPs:${NC}"
    for domain in "${DOMAINS[@]}"; do
        if grep -q "$domain" /etc/hosts; then
            CURRENT_IP=$(grep "$domain" /etc/hosts | awk '{print $1}' | head -1)
            echo -e "  ${YELLOW}$domain${NC} → ${RED}$CURRENT_IP${NC}"
        fi
    done

    echo -e "\n${YELLOW}Would you like to add missing domains? (y/n)${NC}"
    read -r response
    if [[ "$response" == "y" ]]; then
        for domain in "${DOMAINS[@]}"; do
            if ! grep -q "$domain" /etc/hosts; then
                echo -e "${GREEN}Adding: $NEW_IP $domain${NC}"
                echo "$NEW_IP $domain" | $SUDO tee -a /etc/hosts > /dev/null
            fi
        done
    fi
else
    # Apply changes
    $SUDO mv "$TEMP_FILE" /etc/hosts
    echo -e "${GREEN}✓ Updated /etc/hosts successfully${NC}"

    # Show new state
    echo -e "\n${BLUE}New entries with $NEW_IP:${NC}"
    grep "$NEW_IP" /etc/hosts | grep -E "$(IFS='|'; echo "${DOMAINS[*]}")"
fi

# Verify changes
echo -e "\n${BLUE}Verification:${NC}"
for domain in "${DOMAINS[@]}"; do
    if grep -q "$domain" /etc/hosts; then
        IP=$(grep "$domain" /etc/hosts | awk '{print $1}' | head -1)
        if [ "$IP" == "$NEW_IP" ]; then
            echo -e "  ${GREEN}✓${NC} $domain → $IP"
        else
            echo -e "  ${RED}✗${NC} $domain → $IP (expected $NEW_IP)"
        fi
    else
        echo -e "  ${YELLOW}!${NC} $domain (not in /etc/hosts)"
    fi
done

echo -e "\n${GREEN}Done!${NC}"
echo -e "${BLUE}Backup saved to: $BACKUP_FILE${NC}"

# Check if nginx container is running and offer to restart it
if docker ps --format "{{.Names}}" | grep -q "co-nginx-service"; then
    echo -e "\n${BLUE}Nginx proxy detected. Restarting to apply IP changes...${NC}"
    docker restart co-nginx-service > /dev/null 2>&1

    # Wait for nginx to be ready
    echo -e "${BLUE}Waiting for nginx to be ready...${NC}"
    sleep 3

    # Check nginx status
    if docker ps --filter "name=co-nginx-service" --format "{{.Status}}" | grep -q "Up"; then
        echo -e "${GREEN}✓ Nginx restarted successfully${NC}"

        # Also restart other services that might cache IPs
        echo -e "\n${BLUE}Restarting other services that might cache IPs...${NC}"

        # Restart Authelia if running
        if docker ps --format "{{.Names}}" | grep -q "co-authelia-service"; then
            docker restart co-authelia-service > /dev/null 2>&1
            echo -e "${GREEN}✓ Authelia restarted${NC}"
        fi

        # Restart Homepage services if running
        if docker ps --format "{{.Names}}" | grep -q "co-homepage"; then
            docker restart co-homepage-service co-homepage-iframe-proxy > /dev/null 2>&1
            echo -e "${GREEN}✓ Homepage services restarted${NC}"
        fi

        echo -e "\n${GREEN}All services have been restarted with the new IP configuration${NC}"
        echo -e "${BLUE}You may need to clear your browser cache or use incognito mode${NC}"
    else
        echo -e "${YELLOW}Warning: Nginx may not have started properly. Check logs with:${NC}"
        echo -e "  docker logs co-nginx-service"
    fi
else
    echo -e "\n${YELLOW}Note: Nginx container not found. If using Docker services, you may need to:${NC}"
    echo -e "  1. Start the services: ${GREEN}docker compose up -d${NC}"
    echo -e "  2. Or restart nginx manually: ${GREEN}docker restart co-nginx-service${NC}"
fi