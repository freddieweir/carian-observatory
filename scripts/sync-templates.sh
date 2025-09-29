#!/bin/bash

# sync-templates.sh - Bidirectional Template Synchronization for Carian Observatory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MODE="forward"
INTERACTIVE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --reverse|-r)
            MODE="reverse"
            shift
            ;;
        --check|-c)
            MODE="check"
            shift
            ;;
        --interactive|-i)
            INTERACTIVE=true
            shift
            ;;
        --help|-h)
            echo "sync-templates.sh - Bidirectional Template Synchronization"
            echo ""
            echo "Usage: ./sync-templates.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --reverse, -r     Update templates from modified real files"
            echo "  --check, -c       Check for files newer than templates"
            echo "  --interactive, -i Interactive mode with prompts"
            echo "  --help, -h        Show this help"
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            exit 1
            ;;
    esac
done

# Function to sanitize domain for template
sanitize_domain() {
    local content="$1"
    local domain=""

    if [[ -f "$SCRIPT_DIR/.env" ]]; then
        domain=$(grep -E "^(PRIMARY_DOMAIN|PRODUCTION_DOMAIN)=" "$SCRIPT_DIR/.env" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d ' ')
    fi

    if [[ -n "$domain" ]]; then
        echo "$content" | sed "s/${domain}/yourdomain.com/g"
    else
        echo "$content" | sed -E 's/[a-zA-Z0-9.-]+\.(com|net|org)/yourdomain.com/g'
    fi
}

# Function to check if file is newer than template
is_newer() {
    local real_file="$1"
    local template_file="$2"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    if [[ ! -f "$real_file" ]]; then
        return 1
    fi

    if [[ "$real_file" -nt "$template_file" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to update template from real file
update_template() {
    local real_file="$1"
    local template_file="$2"
    local description="$3"

    echo -e "${CYAN}  Processing: $description${NC}"
    echo "     $real_file → $template_file"

    mkdir -p "$(dirname "$template_file")"

    local content
    content=$(cat "$real_file")
    local sanitized
    sanitized=$(sanitize_domain "$content")

    if [[ "$INTERACTIVE" == true ]]; then
        echo -e "${YELLOW}  Update template? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "  Skipped"
            return
        fi
    fi

    echo "$sanitized" > "$template_file"
    echo -e "${GREEN}  Updated${NC}"
}

# Function to check outdated templates
check_outdated() {
    echo -e "${BLUE}Checking for outdated templates...${NC}"
    echo

    local found=false
    local script_dirs=("scripts" "scripts/infrastructure" "scripts/authentication" "scripts/certificates" "scripts/onepassword" "scripts/monitoring")

    for script_dir in "${script_dirs[@]}"; do
        local real_dir="$SCRIPT_DIR/$script_dir"
        local template_dir="$TEMPLATES_DIR/$script_dir"

        if [[ -d "$real_dir" ]]; then
            for real_file in "$real_dir"/*.sh; do
                if [[ -f "$real_file" ]]; then
                    local filename=$(basename "$real_file")
                    local template_file="$template_dir/${filename}.template"

                    if is_newer "$real_file" "$template_file"; then
                        if [[ "$found" == false ]]; then
                            echo -e "${YELLOW}Files newer than templates:${NC}"
                            found=true
                        fi
                        echo "  $filename in $script_dir"
                    fi
                fi
            done
        fi
    done

    if [[ "$found" == false ]]; then
        echo -e "${GREEN}All templates are up to date!${NC}"
    else
        echo -e "${YELLOW}Run with --reverse to update templates${NC}"
    fi
}

# Function to reverse sync
reverse_sync() {
    echo -e "${BLUE}Updating templates from real files...${NC}"
    echo

    local updated=0
    local script_dirs=("scripts" "scripts/infrastructure" "scripts/authentication" "scripts/certificates" "scripts/onepassword" "scripts/monitoring")

    for script_dir in "${script_dirs[@]}"; do
        local real_dir="$SCRIPT_DIR/$script_dir"
        local template_dir="$TEMPLATES_DIR/$script_dir"
        local header_shown=false

        if [[ -d "$real_dir" ]]; then
            for real_file in "$real_dir"/*.sh; do
                if [[ -f "$real_file" ]]; then
                    local filename=$(basename "$real_file")
                    local template_file="$template_dir/${filename}.template"

                    if is_newer "$real_file" "$template_file"; then
                        if [[ "$header_shown" == false ]]; then
                            echo -e "${GREEN}$(basename "$script_dir") Scripts${NC}"
                            header_shown=true
                        fi

                        update_template "$real_file" "$template_file" "$filename script"
                        ((updated++))
                    fi
                fi
            done
        fi
    done

    echo
    if [[ $updated -eq 0 ]]; then
        echo -e "${GREEN}No templates needed updating${NC}"
    else
        echo -e "${GREEN}Updated $updated templates${NC}"
        echo -e "${YELLOW}Review changes before committing${NC}"
    fi
}

# Function to forward sync
forward_sync() {
    echo -e "${BLUE}Generating files from templates...${NC}"

    if [[ -f "$SCRIPT_DIR/create-all-from-templates.sh" ]]; then
        bash "$SCRIPT_DIR/create-all-from-templates.sh"
    else
        echo "Error: create-all-from-templates.sh not found"
        exit 1
    fi
}

# Main execution
echo -e "${BLUE}Carian Observatory Template Sync${NC}"

case $MODE in
    "forward")
        echo "Mode: Forward sync (templates → real files)"
        ;;
    "reverse")
        echo "Mode: Reverse sync (real files → templates)"
        ;;
    "check")
        echo "Mode: Check for outdated templates"
        ;;
esac

echo

case $MODE in
    "forward")
        forward_sync
        ;;
    "reverse")
        reverse_sync
        ;;
    "check")
        check_outdated
        ;;
esac

echo -e "${BLUE}Template sync complete!${NC}"