#!/bin/bash

# create-scripts.sh - 1Password Connect Service
# Generates working scripts from templates with domain substitution
# Part of the template-based security system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR"
TARGET_DIR="../../../../services/onepassword/scripts"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Creating 1Password Connect scripts from templates...${NC}"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Process each template file
for template_file in "$TEMPLATE_DIR"/*.template; do
    if [[ -f "$template_file" ]]; then
        filename=$(basename "$template_file" .template)
        target_file="$TARGET_DIR/$filename"

        echo -e "${YELLOW}Processing: $filename${NC}"

        # Copy template to target with domain substitution
        # Note: These scripts don't currently have domain placeholders
        # but keeping the structure for consistency
        sed "s/yourdomain\.com/\${DOMAIN:-yourdomain.com}/g" "$template_file" > "$target_file"

        # Make scripts executable
        if [[ "$filename" == *.sh ]]; then
            chmod +x "$target_file"
        fi

        echo -e "${GREEN}✓ Created: $target_file${NC}"
    fi
done

echo -e "${GREEN}✅ 1Password Connect scripts generated successfully!${NC}"
echo -e "${BLUE}ℹ️  Scripts are gitignored for security - templates are tracked instead${NC}"