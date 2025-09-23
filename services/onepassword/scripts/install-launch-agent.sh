#!/bin/bash
# Install macOS Launch Agent for 1Password Connect Auto-Restart

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"
PLIST_NAME="com.carian-observatory.onepassword-connect"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing 1Password Connect Launch Agent${NC}"

# Create the Launch Agent plist
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>

    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/auto-restart-monitor.sh</string>
        <string>monitor</string>
    </array>

    <key>WorkingDirectory</key>
    <string>$SERVICE_DIR</string>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/1password-connect-agent.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/1password-connect-agent.error.log</string>

    <key>ProcessType</key>
    <string>Background</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
        <key>LANG</key>
        <string>en_US.UTF-8</string>
    </dict>

    <!-- Only run when user is logged in -->
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
EOF

echo -e "${GREEN}✓ Launch Agent plist created at: $PLIST_PATH${NC}"

# Load the agent
if launchctl load "$PLIST_PATH"; then
    echo -e "${GREEN}✓ Launch Agent loaded successfully${NC}"
else
    echo -e "${RED}✗ Failed to load Launch Agent${NC}"
    exit 1
fi

# Start the agent
if launchctl start "$PLIST_NAME"; then
    echo -e "${GREEN}✓ Launch Agent started${NC}"
else
    echo -e "${YELLOW}⚠ Launch Agent may already be running${NC}"
fi

echo -e "\n${CYAN}Launch Agent Installation Complete${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "Agent Name: ${YELLOW}$PLIST_NAME${NC}"
echo -e "Config File: ${YELLOW}$PLIST_PATH${NC}"
echo -e "Logs: ${YELLOW}/tmp/1password-connect-agent.log${NC}"
echo -e "Error Logs: ${YELLOW}/tmp/1password-connect-agent.error.log${NC}"

echo -e "\n${YELLOW}Management Commands:${NC}"
echo -e "  Check status: ${GREEN}launchctl list | grep onepassword${NC}"
echo -e "  Stop agent:   ${GREEN}launchctl stop $PLIST_NAME${NC}"
echo -e "  Start agent:  ${GREEN}launchctl start $PLIST_NAME${NC}"
echo -e "  Unload agent: ${GREEN}launchctl unload $PLIST_PATH${NC}"
echo -e "  Remove agent: ${GREEN}rm $PLIST_PATH${NC}"

echo -e "\n${GREEN}The agent will now automatically monitor 1Password Connect and prompt for Touch ID when restarts are needed.${NC}"