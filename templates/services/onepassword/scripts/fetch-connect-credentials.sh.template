#!/bin/bash
# Fetch 1Password Connect credentials using 1Password CLI with Touch ID
# This script retrieves the service account token from 1Password vault
# and creates the credentials JSON file dynamically

set -e

# Configuration
ITEM_NAME="Service Account Auth Token: admin_sister_service"
VAULT_NAME="" # Leave empty to search all vaults, or specify vault name
CREDENTIALS_FILE="/tmp/1password-credentials.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Fetching 1Password Connect credentials...${NC}"

# Check if op CLI is installed
if ! command -v op &> /dev/null; then
    echo -e "${RED}Error: 1Password CLI (op) is not installed${NC}"
    echo "Install it with: brew install --cask 1password-cli"
    exit 1
fi

# Sign in to 1Password (will prompt for Touch ID)
echo -e "${GREEN}Authenticating with 1Password (Touch ID required)...${NC}"
if ! op whoami &> /dev/null; then
    eval $(op signin)
fi

# Fetch the credentials from 1Password
echo -e "${YELLOW}Retrieving service account credentials...${NC}"

# Try to get the item - adjust field names as needed based on your item structure
if [ -n "$VAULT_NAME" ]; then
    CREDENTIALS=$(op item get "$ITEM_NAME" --vault "$VAULT_NAME" --format json 2>/dev/null) || {
        echo -e "${RED}Failed to retrieve credentials from vault: $VAULT_NAME${NC}"
        exit 1
    }
else
    CREDENTIALS=$(op item get "$ITEM_NAME" --format json 2>/dev/null) || {
        echo -e "${RED}Failed to retrieve credentials. Item name: $ITEM_NAME${NC}"
        echo "Available items containing 'Service Account':"
        op item list --format json | jq -r '.[] | select(.title | contains("Service Account")) | .title'
        exit 1
    }
fi

# Extract the credentials JSON from the item
# This assumes the credentials are stored in a field called "credential" or in a file attachment
# Adjust based on how you've stored it in 1Password

# Option 1: If stored as a secure note or in a field
CREDS_JSON=$(echo "$CREDENTIALS" | jq -r '.fields[] | select(.label == "credential" or .label == "json" or .label == "credentials") | .value' 2>/dev/null)

# Option 2: If stored as a document/attachment
if [ -z "$CREDS_JSON" ] || [ "$CREDS_JSON" = "null" ]; then
    echo -e "${YELLOW}Checking for file attachments...${NC}"
    ATTACHMENT_ID=$(echo "$CREDENTIALS" | jq -r '.files[0].id // empty' 2>/dev/null)
    if [ -n "$ATTACHMENT_ID" ]; then
        CREDS_JSON=$(op document get "$ATTACHMENT_ID" 2>/dev/null)
    fi
fi

# Option 3: If the entire item value is the JSON
if [ -z "$CREDS_JSON" ] || [ "$CREDS_JSON" = "null" ]; then
    CREDS_JSON=$(echo "$CREDENTIALS" | jq -r '.fields[] | select(.purpose == "NOTES") | .value' 2>/dev/null)
fi

if [ -z "$CREDS_JSON" ] || [ "$CREDS_JSON" = "null" ]; then
    echo -e "${RED}Error: Could not extract credentials JSON from 1Password item${NC}"
    echo "Debug info - Available fields:"
    echo "$CREDENTIALS" | jq '.fields[] | {label: .label, purpose: .purpose}'
    exit 1
fi

# Write credentials to temporary file
echo "$CREDS_JSON" > "$CREDENTIALS_FILE"

# Validate the JSON
if ! jq empty "$CREDENTIALS_FILE" 2>/dev/null; then
    echo -e "${RED}Error: Retrieved credentials are not valid JSON${NC}"
    rm -f "$CREDENTIALS_FILE"
    exit 1
fi

# Set restrictive permissions
chmod 600 "$CREDENTIALS_FILE"

echo -e "${GREEN}✓ Credentials retrieved and saved to: $CREDENTIALS_FILE${NC}"
echo -e "${YELLOW}Note: This file will be automatically cleaned up when containers stop${NC}"

# Return the path for docker-compose to use
echo "$CREDENTIALS_FILE"