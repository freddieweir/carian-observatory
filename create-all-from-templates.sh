#!/bin/bash
# Master template processor for Carian Observatory
# Generates all configuration files and scripts from co-located .template files
# Templates are stored alongside their generated counterparts
# This script should be run locally - generated files are gitignored for security

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Carian Observatory Template Processor${NC}"
echo "Generating all configuration files and scripts from co-located .template files..."
echo

# Source environment variables from .env file
ENV_FILE="$SCRIPT_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
    echo -e "${GREEN}Loading environment variables from .env${NC}"

    # Check if .env contains 1Password references
    if grep -q "op://" "$ENV_FILE"; then
        echo -e "${YELLOW}  ⚠️  Detected 1Password references in .env${NC}"
        echo -e "${YELLOW}  📝 Using .env template values for generation${NC}"

        # Create temporary .env without 1Password references for processing
        TEMP_ENV_FILE=$(mktemp)
        # Replace 1Password references with placeholder values for template processing
        sed 's/{{ op:\/\/[^}]*}}/PLACEHOLDER_VALUE/g' "$ENV_FILE" > "$TEMP_ENV_FILE"

        set -a
        source "$TEMP_ENV_FILE"
        set +a

        # Clean up temp file
        rm "$TEMP_ENV_FILE"
    else
        set -a
        source "$ENV_FILE"
        set +a
    fi

    # Extract PRIMARY_DOMAIN (or PRODUCTION_DOMAIN) for simple substitution scripts
    PRIMARY_DOMAIN=$(grep "^PRIMARY_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2 | sed 's/{{ op:\/\/[^}]*}}/corporateseas.com/g')
    if [[ -z "$PRIMARY_DOMAIN" ]] || [[ "$PRIMARY_DOMAIN" == "PLACEHOLDER_VALUE" ]]; then
        # Try PRODUCTION_DOMAIN instead
        PRIMARY_DOMAIN=$(grep "^PRODUCTION_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2 | sed 's/{{ op:\/\/[^}]*}}/corporateseas.com/g')
    fi
    if [[ -z "$PRIMARY_DOMAIN" ]] || [[ "$PRIMARY_DOMAIN" == "PLACEHOLDER_VALUE" ]]; then
        # Try to extract domain from .env.template
        if [[ -f "$SCRIPT_DIR/.env.template" ]]; then
            PRIMARY_DOMAIN=$(grep "^PRODUCTION_DOMAIN=" "$SCRIPT_DIR/.env.template" | cut -d'=' -f2)
            if [[ -z "$PRIMARY_DOMAIN" ]]; then
                PRIMARY_DOMAIN=$(grep "^PRIMARY_DOMAIN=" "$SCRIPT_DIR/.env.template" | cut -d'=' -f2)
            fi
        fi
        if [[ -z "$PRIMARY_DOMAIN" ]]; then
            echo -e "${RED}Error: PRODUCTION_DOMAIN or PRIMARY_DOMAIN not found in .env file${NC}"
            echo "Please set PRODUCTION_DOMAIN in .env file"
            exit 1
        fi
    fi
else
    echo -e "${RED}Error: .env file not found at $ENV_FILE${NC}"
    echo "Please create .env file from .env.template first"
    exit 1
fi

echo -e "${GREEN}Using domain: $PRIMARY_DOMAIN${NC}"
echo

# Function to process templates with environment variable substitution
process_envsubst_template() {
    local template_file="$1"
    local output_file="$2"
    local description="$3"

    echo "  📄 $description"
    echo "     $template_file → $output_file"

    # Ensure output directory exists
    mkdir -p "$(dirname "$output_file")"

    # Use envsubst for environment variable substitution
    envsubst < "$template_file" > "$output_file"
}

# Function to process templates with simple domain substitution
process_domain_template() {
    local template_file="$1"
    local output_file="$2"
    local description="$3"

    echo "  📄 $description"
    echo "     $template_file → $output_file"

    # Ensure output directory exists
    mkdir -p "$(dirname "$output_file")"

    # Use sed for simple domain substitution
    sed "s/yourdomain\.com/$PRIMARY_DOMAIN/g" "$template_file" > "$output_file"

    # Make scripts executable
    if [[ "$output_file" == *.sh ]]; then
        chmod +x "$output_file"
    fi
}

echo -e "${BLUE}📁 Processing Root Templates${NC}"
if [[ -f "$SCRIPT_DIR/.env.template" ]]; then
    process_envsubst_template "$SCRIPT_DIR/.env.template" "$SCRIPT_DIR/.env" "Main environment configuration"
else
    echo -e "${YELLOW}  ⚠️  .env.template not found - skipping${NC}"
fi
echo

echo -e "${BLUE}📁 Processing Scripts${NC}"

# Function to process all templates in a directory
process_directory_templates() {
    local dir="$1"
    local description="$2"

    if [[ -d "$dir" ]]; then
        local found_templates=false
        for template in "$dir"/*.sh.template; do
            if [[ -f "$template" ]]; then
                if [[ "$found_templates" == false ]]; then
                    echo -e "${GREEN}  $description${NC}"
                    found_templates=true
                fi
                local output_file="${template%.template}"
                local filename=$(basename "$template" .template)
                process_domain_template \
                    "$template" \
                    "$output_file" \
                    "$(basename "$dir") $filename"
            fi
        done
    fi
}

# Process script directories
process_directory_templates "$SCRIPT_DIR/scripts/infrastructure" "🏗️ Infrastructure Scripts"
process_directory_templates "$SCRIPT_DIR/scripts/authentication" "🔐 Authentication Scripts"
process_directory_templates "$SCRIPT_DIR/scripts/certificates" "📜 Certificate Scripts"
process_directory_templates "$SCRIPT_DIR/scripts/onepassword" "🔑 1Password Scripts"
process_directory_templates "$SCRIPT_DIR/scripts/monitoring" "📊 Monitoring Scripts"
process_directory_templates "$SCRIPT_DIR/scripts/migration" "🚀 Migration Scripts"

# Process root-level scripts
echo -e "${GREEN}  📝 Root-level Scripts${NC}"
for template in "$SCRIPT_DIR/scripts"/*.sh.template; do
    if [[ -f "$template" ]]; then
        local output_file="${template%.template}"
        local filename=$(basename "$template" .template)
        process_domain_template \
            "$template" \
            "$output_file" \
            "Root script $filename"
    fi
done

echo

echo -e "${BLUE}📁 Processing Service Templates${NC}"

# Process service configuration templates
if [[ -f "$SCRIPT_DIR/services/authelia/configs/configuration.yml.template" ]]; then
    echo -e "${GREEN}  🔐 Authelia Configuration${NC}"
    process_envsubst_template \
        "$SCRIPT_DIR/services/authelia/configs/configuration.yml.template" \
        "$SCRIPT_DIR/services/authelia/configs/configuration.yml" \
        "Authelia main configuration"
fi

if [[ -f "$SCRIPT_DIR/services/nginx/configs/https.conf.template" ]]; then
    echo -e "${GREEN}  🌐 Nginx Configuration${NC}"
    process_envsubst_template \
        "$SCRIPT_DIR/services/nginx/configs/https.conf.template" \
        "$SCRIPT_DIR/services/nginx/configs/https.conf" \
        "Nginx HTTPS configuration"
fi

if [[ -f "$SCRIPT_DIR/services/glance/configs/glance.yml.template" ]]; then
    echo -e "${GREEN}  👁️ Glance Configuration${NC}"
    process_envsubst_template \
        "$SCRIPT_DIR/services/glance/configs/glance.yml.template" \
        "$SCRIPT_DIR/services/glance/configs/glance.yml" \
        "Glance dashboard configuration"
fi

if [[ -f "$SCRIPT_DIR/services/monitoring/alertmanager/alertmanager.yml.template" ]]; then
    echo -e "${GREEN}  🚨 Alertmanager Configuration${NC}"
    process_envsubst_template \
        "$SCRIPT_DIR/services/monitoring/alertmanager/alertmanager.yml.template" \
        "$SCRIPT_DIR/services/monitoring/alertmanager/alertmanager.yml" \
        "Alertmanager configuration"
fi

# Process Homepage templates
echo -e "${GREEN}  🏠 Homepage Service${NC}"

# Homepage configs (use envsubst for environment variables)
for template in "$SCRIPT_DIR/services/homepage/configs"/*.yaml.template; do
    if [[ -f "$template" ]]; then
        local output_file="${template%.template}"
        local filename=$(basename "$template" .template)
        process_envsubst_template \
            "$template" \
            "$output_file" \
            "Homepage $filename config"
    fi
done

# Homepage scripts (use domain substitution)
for template in "$SCRIPT_DIR/services/homepage/scripts"/*.sh.template; do
    if [[ -f "$template" ]]; then
        local output_file="${template%.template}"
        local filename=$(basename "$template" .template)
        process_domain_template \
            "$template" \
            "$output_file" \
            "Homepage $filename script"
    fi
done

echo
echo -e "${GREEN}✅ Template processing complete!${NC}"
echo
echo -e "${BLUE}Generated Files Summary:${NC}"
echo "  📂 Root: .env"
echo "  📂 Scripts: scripts/infrastructure/, scripts/authentication/, scripts/certificates/"
echo "  📂 Scripts: scripts/onepassword/, scripts/monitoring/"
echo "  📂 Authelia: services/authelia/configs/configuration.yml"
echo "  📂 Nginx: services/nginx/configs/https.conf"
echo "  📂 Homepage: services/homepage/configs/*.yaml, services/homepage/scripts/*.sh"
echo
echo -e "${YELLOW}📋 Important Notes:${NC}"
echo "  • All generated files are gitignored for security"
echo "  • Template files (.template) are co-located with generated files"
echo "  • Only .template files are safe to commit to git"
echo "  • Re-run this script after updating any .template files"
echo "  • Check .env file for required environment variables"
echo
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "  1. Review generated .env file and set required values"
echo "  2. Start services: docker compose up -d"
echo "  3. Check nginx config: docker exec co-nginx-service nginx -t"