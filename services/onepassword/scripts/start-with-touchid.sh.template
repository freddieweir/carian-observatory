#!/bin/bash
# Start 1Password Connect with Touch ID authentication
# This script fetches credentials securely and starts the containers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_FILE="/tmp/1password-credentials.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     1Password Connect Secure Startup with Touch ID     ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

# Clean up function
cleanup() {
    if [ -f "$CREDENTIALS_FILE" ]; then
        echo -e "\n${YELLOW}Cleaning up credentials file...${NC}"
        shred -u "$CREDENTIALS_FILE" 2>/dev/null || rm -f "$CREDENTIALS_FILE"
        echo -e "${GREEN}✓ Credentials securely removed${NC}"
    fi
}

# Set up trap to clean up on exit
trap cleanup EXIT INT TERM

# Step 1: Fetch credentials using Touch ID
echo -e "\n${GREEN}Step 1: Fetching credentials from 1Password...${NC}"
if ! "$SCRIPT_DIR/fetch-connect-credentials.sh" > /dev/null; then
    echo -e "${RED}Failed to fetch credentials${NC}"
    exit 1
fi

# Step 2: Create a temporary docker-compose override
echo -e "\n${GREEN}Step 2: Creating secure docker-compose configuration...${NC}"
cat > "$SERVICE_DIR/docker-compose.override.yml" << EOF
# Temporary override for secure credential mounting
# This file is auto-generated and should not be committed
version: '3.8'

services:
  onepassword-connect-sync:
    volumes:
      - $CREDENTIALS_FILE:/home/opuser/.op/1password-credentials.json:ro
      - onepassword-data:/home/opuser/.op/data
EOF

# Step 3: Start the containers
echo -e "\n${GREEN}Step 3: Starting 1Password Connect services...${NC}"
cd "$SERVICE_DIR"

# Stop any existing containers
docker compose down 2>/dev/null || true

# Start with the override file
if docker compose up -d; then
    echo -e "${GREEN}✓ 1Password Connect services started successfully${NC}"

    # Wait for health checks
    echo -e "\n${YELLOW}Waiting for services to be healthy...${NC}"
    sleep 5

    # Check status
    docker compose ps

    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ 1Password Connect is now running with Touch ID auth${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "\nAPI endpoint: ${GREEN}http://localhost:8090${NC}"
    echo -e "Health check: ${GREEN}curl http://localhost:8090/health${NC}"

    # Clean up override file (credentials file cleaned by trap)
    rm -f "$SERVICE_DIR/docker-compose.override.yml"
else
    echo -e "${RED}Failed to start 1Password Connect services${NC}"
    rm -f "$SERVICE_DIR/docker-compose.override.yml"
    exit 1
fi