#!/bin/bash
# =============================================================================
# DEPLOY CONFIGURATION WITH ENVIRONMENT VARIABLES
# =============================================================================
# This script processes template files with environment variable substitution
# Usage: ./deploy-config.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please copy .env.example to .env and configure your settings"
    exit 1
fi

# Load environment variables
source .env

echo -e "${GREEN}Deploying configuration with environment variables...${NC}"

# =============================================================================
# Process nginx configuration template
# =============================================================================
if [ -f "nginx/https.conf.template" ]; then
    echo "Processing nginx configuration..."
    envsubst < nginx/https.conf.template > nginx/https.conf
    echo -e "${GREEN}✓ Generated nginx/https.conf${NC}"
fi

# =============================================================================
# Process docker-compose template if exists
# =============================================================================
if [ -f "docker-compose.yaml.template" ]; then
    echo "Processing docker-compose configuration..."
    envsubst < docker-compose.yaml.template > docker-compose.yaml
    echo -e "${GREEN}✓ Generated docker-compose.yaml${NC}"
fi

# =============================================================================
# Process Authelia configuration if template exists
# =============================================================================
if [ -f "configs/authelia-canary/configuration.yml.template" ]; then
    echo "Processing Authelia configuration..."
    envsubst < configs/authelia-canary/configuration.yml.template > configs/authelia-canary/configuration.yml
    echo -e "${GREEN}✓ Generated Authelia configuration${NC}"
fi

# =============================================================================
# Validate required environment variables
# =============================================================================
echo -e "\n${YELLOW}Validating configuration...${NC}"

required_vars=(
    "PRODUCTION_DOMAIN"
    "CANARY_DOMAIN"
    "WEBUI_SUBDOMAIN"
    "AUTH_SUBDOMAIN"
    "AUTHELIA_SESSION_SECRET"
    "AUTHELIA_STORAGE_ENCRYPTION_KEY"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo -e "${RED}Error: Missing required environment variables:${NC}"
    printf '%s\n' "${missing_vars[@]}"
    exit 1
fi

echo -e "${GREEN}✓ All required variables are set${NC}"

# =============================================================================
# Generate certificate generation script with domains
# =============================================================================
cat > scripts/generate-certs-from-env.sh << EOF
#!/bin/bash
# Auto-generated certificate generation script
# Generated on: $(date)

# Production certificates
./scripts/generate-canary-certs.sh \\
    --domain "${WEBUI_SUBDOMAIN}.${PRODUCTION_DOMAIN}" \\
    --domain "${AUTH_SUBDOMAIN}.${PRODUCTION_DOMAIN}" \\
    --domain "${PERPLEXICA_SUBDOMAIN}.${PRODUCTION_DOMAIN}" \\
    --domain "${SEARXNG_SUBDOMAIN}.${PRODUCTION_DOMAIN}"

# Canary certificates  
./scripts/generate-canary-certs.sh \\
    --domain "${WEBUI_SUBDOMAIN}.${CANARY_DOMAIN}" \\
    --domain "${AUTH_SUBDOMAIN}.${CANARY_DOMAIN}" \\
    --domain "${PERPLEXICA_SUBDOMAIN}.${CANARY_DOMAIN}" \\
    --domain "${SEARXNG_SUBDOMAIN}.${CANARY_DOMAIN}"
EOF

chmod +x scripts/generate-certs-from-env.sh
echo -e "${GREEN}✓ Generated certificate generation script${NC}"

# =============================================================================
# Display configuration summary
# =============================================================================
echo -e "\n${GREEN}Configuration Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Production Domain: ${PRODUCTION_DOMAIN}"
echo "  - WebUI: ${WEBUI_SUBDOMAIN}.${PRODUCTION_DOMAIN}"
echo "  - Auth: ${AUTH_SUBDOMAIN}.${PRODUCTION_DOMAIN}"
echo "  - Perplexica: ${PERPLEXICA_SUBDOMAIN}.${PRODUCTION_DOMAIN}"
echo ""
echo "Canary Domain: ${CANARY_DOMAIN}"
echo "  - WebUI: ${WEBUI_SUBDOMAIN}.${CANARY_DOMAIN}"
echo "  - Auth: ${AUTH_SUBDOMAIN}.${CANARY_DOMAIN}"
echo "  - SearXNG: ${SEARXNG_SUBDOMAIN}.${CANARY_DOMAIN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${GREEN}✓ Configuration deployment complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review generated configuration files"
echo "  2. Generate SSL certificates: ./scripts/generate-certs-from-env.sh"
echo "  3. Start services: docker compose up -d"