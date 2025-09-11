#!/bin/bash
# =============================================================================
# SANITIZE HARDCODED DOMAINS
# =============================================================================
# This script replaces all hardcoded domains with generic placeholders
# Run this before committing to git for security

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Sanitizing hardcoded domains...${NC}"

# Define replacements
declare -A replacements=(
    ["yourdomain.com"]="yourdomain.com"
    ["test.yourdomain.com"]="test.yourdomain.com"
    ["webui-m4-canary.yourdomain.com"]="webui-canary.yourdomain.com"
    ["auth-m4.yourdomain.com"]="auth.yourdomain.com"
    ["auth-status-m4.yourdomain.com"]="auth-status.yourdomain.com"
    ["webui-m4.yourdomain.com"]="webui.yourdomain.com"
    ["perplexica-m4.yourdomain.com"]="perplexica.yourdomain.com"
    ["webui-m2.yourdomain.com"]="webui-m2.yourdomain.com"
    ["perplexica-m2.yourdomain.com"]="perplexica-m2.yourdomain.com"
    ["auth-test.yourdomain.com"]="auth.test.yourdomain.com"
    ["webui-test.yourdomain.com"]="webui.test.yourdomain.com"
    ["perplexica-test.yourdomain.com"]="perplexica.test.yourdomain.com"
    ["searxng-test.yourdomain.com"]="search.test.yourdomain.com"
)

# Files to clean (excluding sensitive directories)
files_to_clean=(
    "docs/*.md"
    "scripts/*.sh"
    "migration/*.sh"
    "migration/*.md"
    "*.md"
    "docker-compose*.yaml"
    "configs/docker-compose*.yaml"
)

# Backup original files
backup_dir=".backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

for pattern in "${files_to_clean[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            echo "Processing: $file"
            # Create backup
            cp "$file" "$backup_dir/$(basename $file).bak"
            
            # Replace domains
            temp_file=$(mktemp)
            cp "$file" "$temp_file"
            
            for old_domain in "${!replacements[@]}"; do
                new_domain="${replacements[$old_domain]}"
                sed -i '' "s/${old_domain}/${new_domain}/g" "$temp_file" 2>/dev/null || \
                sed -i "s/${old_domain}/${new_domain}/g" "$temp_file"
            done
            
            mv "$temp_file" "$file"
            echo -e "${GREEN}✓${NC} Cleaned: $file"
        fi
    done
done

# Create a mapping file for reference
cat > domain-mapping.txt << EOF
# Domain Mapping Reference
# This file shows the mapping between actual and placeholder domains
# Keep this file private and do not commit to git

Production Domain: yourdomain.com → yourdomain.com
Canary Domain: test.yourdomain.com → test.yourdomain.com

Service Mappings:
- auth-m4.yourdomain.com → auth.yourdomain.com
- webui-m4.yourdomain.com → webui.yourdomain.com
- perplexica-m4.yourdomain.com → perplexica.yourdomain.com
- auth-test.yourdomain.com → auth.test.yourdomain.com
- webui-test.yourdomain.com → webui.test.yourdomain.com
- searxng-test.yourdomain.com → search.test.yourdomain.com
EOF

echo -e "\n${GREEN}Sanitization complete!${NC}"
echo -e "${YELLOW}Backup created in:${NC} $backup_dir"
echo -e "${YELLOW}Mapping reference:${NC} domain-mapping.txt"
echo -e "\n${RED}IMPORTANT:${NC} Add domain-mapping.txt to .gitignore!"