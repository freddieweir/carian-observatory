#!/bin/bash
# Create actual scripts from templates with real domain substitution
# This script should be run locally and the output scripts should be gitignored

set -e

# Source environment variables to get real domain
ENV_FILE="../../../.env"
if [ -f "$ENV_FILE" ]; then
    # Extract PRIMARY_DOMAIN from .env (avoiding 1Password template issues)
    PRIMARY_DOMAIN=$(grep "^PRIMARY_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2)
    if [ -z "$PRIMARY_DOMAIN" ]; then
        echo "Error: PRIMARY_DOMAIN not found in .env file"
        exit 1
    fi
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

echo "Creating scripts with domain: $PRIMARY_DOMAIN"

# Create generate-config.sh from template
echo "Creating generate-config.sh..."
sed "s/yourdomain\.com/$PRIMARY_DOMAIN/g" generate-config.sh.template > generate-config.sh
chmod +x generate-config.sh

# Create start-homepage.sh from template
echo "Creating start-homepage.sh..."
sed "s/yourdomain\.com/$PRIMARY_DOMAIN/g" start-homepage.sh.template > start-homepage.sh
chmod +x start-homepage.sh

echo "Scripts created successfully!"
echo "Note: These scripts contain your real domain and should not be committed to git."