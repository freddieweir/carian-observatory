#!/bin/bash
# Touch ID Prompt with macOS Native Notifications
# Handles user interaction for 1Password Connect authentication
#
# ⚠️  macOS ONLY - Uses osascript for dialogs and notifications

set -e

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ ERROR: This script requires macOS"
    echo "Uses osascript for native dialogs and notifications"
    echo ""
    echo "For other systems, use basic commands:"
    echo "  ./manage-1password-connect.sh start"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to send macOS notification
send_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-Ping}"

    osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
}

# Function to show dialog with Touch ID request
show_touchid_dialog() {
    local result
    result=$(osascript << 'EOF'
tell application "System Events"
    set userChoice to button returned of (display dialog "1Password Connect containers need to restart.

Touch ID authentication is required to fetch credentials from your 1Password vault.

Click OK to authenticate, or Cancel to skip." buttons {"Cancel", "OK"} default button "OK" with title "1Password Connect Authentication" with icon caution)
    return userChoice
end tell
EOF
)
    echo "$result"
}

# Function to show success notification
show_success() {
    send_notification "1Password Connect" "Services restarted successfully" "Glass"
    echo -e "${GREEN}✓ Authentication successful${NC}"
}

# Function to show failure notification
show_failure() {
    local reason="$1"
    send_notification "1Password Connect" "Failed to restart: $reason" "Basso"
    echo -e "${RED}✗ Authentication failed: $reason${NC}"
}

# Function to show skip notification
show_skip() {
    send_notification "1Password Connect" "Authentication skipped - services remain down" "Tink"
    echo -e "${YELLOW}⚠ Authentication skipped${NC}"
}

# Main prompt function
prompt_for_touchid() {
    echo -e "${BLUE}1Password Connect Authentication Required${NC}"
    echo -e "${YELLOW}Containers need Touch ID authentication to restart${NC}"

    # Send initial notification
    send_notification "1Password Connect" "Touch ID authentication needed for container restart"

    # Show dialog
    if user_choice=$(show_touchid_dialog); then
        if [ "$user_choice" = "OK" ]; then
            echo -e "${GREEN}User approved - starting authentication...${NC}"

            # Attempt to restart with Touch ID
            if "$SCRIPT_DIR/manage-1password-connect.sh" start; then
                show_success
                return 0
            else
                show_failure "Failed to authenticate or start services"
                return 1
            fi
        else
            show_skip
            return 1
        fi
    else
        show_skip
        return 1
    fi
}

# Automatic mode (no dialog, just try)
auto_restart() {
    echo -e "${YELLOW}Auto-restart mode - attempting Touch ID authentication...${NC}"
    send_notification "1Password Connect" "Attempting automatic restart with Touch ID"

    if "$SCRIPT_DIR/manage-1password-connect.sh" start; then
        show_success
        return 0
    else
        show_failure "Automatic authentication failed"
        return 1
    fi
}

# Main script logic
case "${1:-prompt}" in
    prompt)
        prompt_for_touchid
        ;;
    auto)
        auto_restart
        ;;
    test)
        send_notification "1Password Connect" "Test notification" "Ping"
        ;;
    *)
        echo -e "${CYAN}Touch ID Prompt Script${NC}"
        echo -e "${YELLOW}Usage: $0 {prompt|auto|test}${NC}"
        echo ""
        echo "  prompt - Show dialog and prompt for Touch ID (default)"
        echo "  auto   - Attempt automatic restart without dialog"
        echo "  test   - Send test notification"
        exit 1
        ;;
esac