#!/bin/bash

# Manage /etc/hosts entries for Open WebUI Canary
# This script adds/removes canary domain entries in /etc/hosts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Load from environment or use defaults
source ${ENV_FILE:-.env} 2>/dev/null || true
CANARY_DOMAIN="${WEBUI_SUBDOMAIN:-webui}-${MACHINE_ID:-canary}.${CANARY_DOMAIN:-example.local}"
HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.backup.$(date +%Y%m%d_%H%M%S)"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get local IP address
get_local_ip() {
    # Try to get the main network interface IP
    local ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
    if [ -z "$ip" ]; then
        # Fallback to localhost
        ip="127.0.0.1"
    fi
    echo "$ip"
}

# Function to check if entry exists
check_entry_exists() {
    grep -q "$CANARY_DOMAIN" "$HOSTS_FILE" 2>/dev/null
}

# Function to add hosts entry
add_hosts_entry() {
    local ip="$1"
    
    print_status "Adding $CANARY_DOMAIN to $HOSTS_FILE..."
    
    # Create backup
    sudo cp "$HOSTS_FILE" "$BACKUP_FILE"
    print_status "Backup created: $BACKUP_FILE"
    
    # Add entry
    echo "$ip $CANARY_DOMAIN" | sudo tee -a "$HOSTS_FILE" > /dev/null
    print_success "Added: $ip $CANARY_DOMAIN"
}

# Function to remove hosts entry
remove_hosts_entry() {
    print_status "Removing $CANARY_DOMAIN from $HOSTS_FILE..."
    
    # Create backup
    sudo cp "$HOSTS_FILE" "$BACKUP_FILE"
    print_status "Backup created: $BACKUP_FILE"
    
    # Remove entry
    sudo sed -i '' "/$CANARY_DOMAIN/d" "$HOSTS_FILE"
    print_success "Removed entries for $CANARY_DOMAIN"
}

# Function to update hosts entry
update_hosts_entry() {
    local ip="$1"
    
    print_status "Updating $CANARY_DOMAIN in $HOSTS_FILE..."
    
    # Create backup
    sudo cp "$HOSTS_FILE" "$BACKUP_FILE"
    print_status "Backup created: $BACKUP_FILE"
    
    # Remove old entry and add new one
    sudo sed -i '' "/$CANARY_DOMAIN/d" "$HOSTS_FILE"
    echo "$ip $CANARY_DOMAIN" | sudo tee -a "$HOSTS_FILE" > /dev/null
    print_success "Updated: $ip $CANARY_DOMAIN"
}

# Function to show current entry
show_current_entry() {
    print_status "Current hosts entries for $CANARY_DOMAIN:"
    grep "$CANARY_DOMAIN" "$HOSTS_FILE" 2>/dev/null || echo "  No entries found"
}

# Function to auto-configure
auto_configure() {
    local ip=$(get_local_ip)
    
    print_status "Auto-configuring hosts entry..."
    print_status "Detected IP: $ip"
    
    if check_entry_exists; then
        print_warning "Entry already exists. Updating..."
        update_hosts_entry "$ip"
    else
        add_hosts_entry "$ip"
    fi
    
    # Verify
    echo ""
    show_current_entry
    
    # Test connectivity
    echo ""
    print_status "Testing connectivity..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$ip:8081/health" | grep -q "200"; then
        print_success "Canary is accessible at http://$ip:8081"
        print_success "You should now be able to access: https://$CANARY_DOMAIN"
    else
        print_warning "Canary may not be running. Start it with: ./manage-canary.sh start"
    fi
}

# Function to show usage
show_usage() {
    echo "Manage /etc/hosts entries for Open WebUI Canary"
    echo ""
    echo "Usage: $0 [COMMAND] [IP]"
    echo ""
    echo "Commands:"
    echo "  add [IP]        Add canary domain to hosts file (default: auto-detect IP)"
    echo "  remove          Remove canary domain from hosts file"
    echo "  update [IP]     Update existing entry (default: auto-detect IP)"
    echo "  show            Show current hosts entries"
    echo "  auto            Auto-configure with detected IP"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 auto                    # Auto-configure with detected IP"
    echo "  $0 add 192.168.1.100       # Add with specific IP"
    echo "  $0 update                  # Update with auto-detected IP"
    echo "  $0 remove                  # Remove all entries"
    echo "  $0 show                    # Show current entries"
    echo ""
}

# Main script logic
case "${1:-auto}" in
    add)
        ip="${2:-$(get_local_ip)}"
        if check_entry_exists; then
            print_warning "Entry already exists. Use 'update' to modify or 'remove' first."
            show_current_entry
        else
            add_hosts_entry "$ip"
            show_current_entry
        fi
        ;;
    remove)
        if check_entry_exists; then
            remove_hosts_entry
        else
            print_warning "No entries found for $CANARY_DOMAIN"
        fi
        ;;
    update)
        ip="${2:-$(get_local_ip)}"
        if check_entry_exists; then
            update_hosts_entry "$ip"
            show_current_entry
        else
            print_warning "No existing entry found. Use 'add' instead."
            add_hosts_entry "$ip"
            show_current_entry
        fi
        ;;
    show)
        show_current_entry
        ;;
    auto)
        auto_configure
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
