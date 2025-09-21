#!/bin/bash
# Generate Monitoring configuration from templates using environment variables
# Template version - uses yourdomain.com placeholders

set -e

# Source environment variables (safely, ignoring 1Password template lines)
ENV_FILE="../../../.env"
if [ -f "$ENV_FILE" ]; then
    set -a  # automatically export all variables
    # Filter out 1Password template lines before sourcing
    grep -v "op://" "$ENV_FILE" | while IFS= read -r line; do
        if [[ "$line" =~ ^[A-Z_]+= ]]; then
            export "$line"
        fi
    done
    # Export domain variables from environment (fallback to yourdomain.com for safety)
    export PRIMARY_DOMAIN=${PRODUCTION_DOMAIN:-yourdomain.com}
    export MONITORING_SUBDOMAIN=${MONITORING_SUBDOMAIN:-monitoring}
    export MONITORING_DOMAIN="${MONITORING_SUBDOMAIN}.${PRIMARY_DOMAIN}"
    set +a
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Generate alertmanager.yml from template
echo "Generating alertmanager.yml from template..."
sed "s/yourdomain.com/${PRIMARY_DOMAIN}/g" "../alertmanager/alertmanager.yml.template" > "../alertmanager/alertmanager.yml"

echo "Monitoring configuration generated successfully!"
echo "Alertmanager will use:"
echo "  - Email from: carian-observatory@${PRIMARY_DOMAIN}"