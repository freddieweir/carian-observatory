#!/bin/bash
# Docker Entrypoint Wrapper for 1Password Connect
# Ensures credentials are available before starting the service

set -e

CREDENTIALS_FILE="/home/opuser/.op/1password-credentials.json"
CREDENTIALS_SOURCE="/tmp/1password-credentials.json"

# Colors for output (if terminal is available)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

echo -e "${YELLOW}Checking for 1Password credentials...${NC}"

# Check if credentials are already mounted
if [ -f "$CREDENTIALS_FILE" ]; then
    echo -e "${GREEN}✓ Credentials found${NC}"
else
    echo -e "${RED}✗ Credentials not found${NC}"

    # Check if credentials exist in /tmp (from host)
    if [ -f "$CREDENTIALS_SOURCE" ]; then
        echo -e "${YELLOW}Copying credentials from host...${NC}"
        cp "$CREDENTIALS_SOURCE" "$CREDENTIALS_FILE"
        chmod 600 "$CREDENTIALS_FILE"
        echo -e "${GREEN}✓ Credentials copied${NC}"
    else
        echo -e "${RED}ERROR: No credentials available${NC}"
        echo "Please run the following on the host:"
        echo "  ./services/onepassword/scripts/manage-1password-connect.sh start"
        exit 1
    fi
fi

# Execute the original entrypoint
exec "$@"