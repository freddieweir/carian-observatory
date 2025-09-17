#!/bin/bash
# Master template processor for Carian Observatory
# Generates all configuration files and scripts from templates directory
# This script should be run locally - generated files are gitignored for security

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Carian Observatory Template Processor${NC}"
echo "Generating all configuration files and scripts from templates..."
echo

# Check if templates directory exists
if [[ ! -d "$TEMPLATES_DIR" ]]; then
    echo -e "${RED}Error: Templates directory not found at $TEMPLATES_DIR${NC}"
    exit 1
fi

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
        # Try to extract domain from templates/.env.template
        if [[ -f "$TEMPLATES_DIR/.env.template" ]]; then
            PRIMARY_DOMAIN=$(grep "^PRODUCTION_DOMAIN=" "$TEMPLATES_DIR/.env.template" | cut -d'=' -f2)
            if [[ -z "$PRIMARY_DOMAIN" ]]; then
                PRIMARY_DOMAIN=$(grep "^PRIMARY_DOMAIN=" "$TEMPLATES_DIR/.env.template" | cut -d'=' -f2)
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
    echo "Please create .env file from templates/.env.template first"
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
if [[ -f "$TEMPLATES_DIR/.env.template" ]]; then
    process_envsubst_template "$TEMPLATES_DIR/.env.template" "$SCRIPT_DIR/.env" "Main environment configuration"
else
    echo -e "${YELLOW}  ⚠️  .env.template not found - skipping${NC}"
fi
echo

echo -e "${BLUE}📁 Processing Scripts${NC}"

# Process infrastructure scripts
echo -e "${GREEN}  🏗️ Infrastructure Scripts${NC}"
if [[ -f "$TEMPLATES_DIR/scripts/infrastructure/add-hosts-entry.sh.template" ]]; then
    process_domain_template \
        "$TEMPLATES_DIR/scripts/infrastructure/add-hosts-entry.sh.template" \
        "$SCRIPT_DIR/scripts/infrastructure/add-hosts-entry.sh" \
        "Host entry management script"
fi

# Process authentication scripts
echo -e "${GREEN}  🔐 Authentication Scripts${NC}"
for template in "$TEMPLATES_DIR/scripts/authentication"/*.sh.template; do
    if [[ -f "$template" ]]; then
        filename=$(basename "$template" .template)
        process_domain_template \
            "$template" \
            "$SCRIPT_DIR/scripts/authentication/$filename" \
            "Authentication $filename script"
    fi
done

# Process certificate scripts
echo -e "${GREEN}  📜 Certificate Scripts${NC}"
for template in "$TEMPLATES_DIR/scripts/certificates"/*.sh.template; do
    if [[ -f "$template" ]]; then
        filename=$(basename "$template" .template)
        process_domain_template \
            "$template" \
            "$SCRIPT_DIR/scripts/certificates/$filename" \
            "Certificate $filename script"
    fi
done

# Process onepassword scripts
echo -e "${GREEN}  🔑 1Password Scripts${NC}"
for template in "$TEMPLATES_DIR/scripts/onepassword"/*.sh.template; do
    if [[ -f "$template" ]]; then
        filename=$(basename "$template" .template)
        process_domain_template \
            "$template" \
            "$SCRIPT_DIR/scripts/onepassword/$filename" \
            "1Password $filename script"
    fi
done

# Process monitoring scripts
echo -e "${GREEN}  📊 Monitoring Scripts${NC}"
for template in "$TEMPLATES_DIR/scripts/monitoring"/*.sh.template; do
    if [[ -f "$template" ]]; then
        filename=$(basename "$template" .template)
        process_domain_template \
            "$template" \
            "$SCRIPT_DIR/scripts/monitoring/$filename" \
            "Monitoring $filename script"
    fi
done

# Process migration scripts
echo -e "${GREEN}  🚀 Migration Scripts${NC}"
for template in "$TEMPLATES_DIR/scripts/migration"/*.sh.template; do
    if [[ -f "$template" ]]; then
        filename=$(basename "$template" .template)
        process_domain_template \
            "$template" \
            "$SCRIPT_DIR/scripts/migration/$filename" \
            "Migration $filename script"
    fi
done

# Process root-level scripts
echo -e "${GREEN}  📝 Root-level Scripts${NC}"
for template in "$TEMPLATES_DIR/scripts"/*.sh.template; do
    if [[ -f "$template" ]]; then
        filename=$(basename "$template" .template)
        process_domain_template \
            "$template" \
            "$SCRIPT_DIR/scripts/$filename" \
            "Root script $filename"
    fi
done

echo

echo -e "${BLUE}📁 Processing Service Templates${NC}"

# Process Authelia templates
echo -e "${GREEN}  🔐 Authelia Configuration${NC}"
if [[ -f "$TEMPLATES_DIR/services/authelia/configs/configuration.yml.template" ]]; then
    process_envsubst_template \
        "$TEMPLATES_DIR/services/authelia/configs/configuration.yml.template" \
        "$SCRIPT_DIR/services/authelia/configs/configuration.yml" \
        "Authelia main configuration"
fi

# Process nginx templates
echo -e "${GREEN}  🌐 Nginx Configuration${NC}"
if [[ -f "$TEMPLATES_DIR/services/nginx/configs/https.conf.template" ]]; then
    process_envsubst_template \
        "$TEMPLATES_DIR/services/nginx/configs/https.conf.template" \
        "$SCRIPT_DIR/services/nginx/configs/https.conf" \
        "Nginx HTTPS configuration"
fi

# Process Homepage templates
echo -e "${GREEN}  🏠 Homepage Service${NC}"

# Homepage configs (use envsubst for environment variables)
for template in "$TEMPLATES_DIR/services/homepage/configs"/*.yaml.template; do
    if [[ -f "$template" ]]; then
        filename=$(basename "$template" .template)
        process_envsubst_template \
            "$template" \
            "$SCRIPT_DIR/services/homepage/configs/$filename" \
            "Homepage $filename config"
    fi
done

# Homepage scripts (use domain substitution)
for template in "$TEMPLATES_DIR/services/homepage/scripts"/*.sh.template; do
    if [[ -f "$template" ]]; then
        filename=$(basename "$template" .template)
        process_domain_template \
            "$template" \
            "$SCRIPT_DIR/services/homepage/scripts/$filename" \
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
echo "  • Templates in templates/ directory are safe to commit"
echo "  • Re-run this script after updating templates"
echo "  • Check .env file for required environment variables"
echo
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "  1. Review generated .env file and set required values"
echo "  2. Start services: docker compose up -d"
echo "  3. Check nginx config: docker exec co-nginx-service nginx -t"