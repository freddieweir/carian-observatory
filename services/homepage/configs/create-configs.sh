#!/bin/bash
# Homepage Config Generation Script
# Generates working configs from templates with environment variable substitution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Homepage Config Generator${NC}"
echo "Generating Homepage configuration files from templates..."

# Source environment variables from the main .env file
ENV_FILE="$SCRIPT_DIR/../../../.env"
if [[ -f "$ENV_FILE" ]]; then
    echo "Loading environment variables from $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
else
    echo -e "${YELLOW}Warning: .env file not found at $ENV_FILE${NC}"
    echo "Using default values where possible"
fi

# Function to substitute environment variables in templates
generate_config() {
    local template_file="$1"
    local output_file="$2"

    if [[ ! -f "$template_file" ]]; then
        echo -e "${RED}Error: Template file $template_file not found${NC}"
        return 1
    fi

    echo "Generating $output_file from $template_file"
    envsubst < "$template_file" > "$output_file"
}

# Generate all config files
generate_config "$CONFIG_DIR/services.yaml.template" "$CONFIG_DIR/services.yaml"
generate_config "$CONFIG_DIR/widgets.yaml.template" "$CONFIG_DIR/widgets.yaml"
generate_config "$CONFIG_DIR/settings.yaml.template" "$CONFIG_DIR/settings.yaml"
generate_config "$CONFIG_DIR/bookmarks.yaml.template" "$CONFIG_DIR/bookmarks.yaml"
generate_config "$CONFIG_DIR/docker.yaml.template" "$CONFIG_DIR/docker.yaml"

# Custom.js and custom.css don't need templating - just ensure they exist
if [[ ! -f "$CONFIG_DIR/custom.js" ]]; then
    echo "// Custom JavaScript disabled - PWA navigation handled at infrastructure level
console.log('[Custom.js] JavaScript navigation disabled');" > "$CONFIG_DIR/custom.js"
fi

if [[ ! -f "$CONFIG_DIR/custom.css" ]]; then
    echo "/* Custom CSS for Homepage dashboard */" > "$CONFIG_DIR/custom.css"
fi

# Display environment variable information for user
echo ""
echo "Environment variables used:"
echo "  - Domain variables: AUTH_DOMAIN, WEBUI_DOMAIN, CANARY_DOMAIN, etc."
echo "  - Search: KAGI_API_KEY (for Kagi search API if desired)"
echo "  - Weather: WEATHER_LATITUDE, WEATHER_LONGITUDE, WEATHER_UNITS"
echo "  - Widgets: WATCHTOWER_API_KEY, NPM_USERNAME, NPM_PASSWORD, etc."

echo -e "${GREEN}✅ Homepage configuration files generated successfully!${NC}"
echo ""
echo "Generated files:"
echo "  - services.yaml (with real domains)"
echo "  - widgets.yaml (with environment variables)"
echo "  - settings.yaml (with custom settings)"
echo "  - bookmarks.yaml (static bookmarks)"
echo "  - docker.yaml (Docker config)"
echo "  - custom.js (JavaScript customizations)"
echo "  - custom.css (CSS customizations)"
echo ""
echo -e "${YELLOW}Note: Generated .yaml files are gitignored for security${NC}"