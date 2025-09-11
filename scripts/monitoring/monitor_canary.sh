#!/bin/bash

# ============================================================================
# Production Claude - Canary Monitor
# ============================================================================
# Monitors communication with Canary Claude instance in VM

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
COMM_DIR="/Volumes/aetherium/Shared Parallel/macOS Dev Files/Claude Communication"
LOG_FILE="$COMM_DIR/communication_log.txt"
LAST_LINE_FILE="/tmp/production_last_line"

# Initialize
touch "$LAST_LINE_FILE"

echo -e "${BLUE}${BOLD}=== Production Canary Monitor ===${NC}"
echo -e "${GREEN}Monitoring canary communications...${NC}"
echo "Communication log: $LOG_FILE"
echo "-----------------------------------"

# Add startup message
echo "[PRODUCTION] $(date '+%Y-%m-%d %H:%M:%S') - MONITOR: Production monitoring started" >> "$LOG_FILE"

# Function to send message to canary
send_to_canary() {
    local message="$1"
    echo "[PRODUCTION] $(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
    echo -e "${BLUE}Sent to Canary: $message${NC}"
}

# Function to process canary responses
process_canary_message() {
    local line="$1"
    
    if [[ "$line" == *"[CANARY]"* ]]; then
        # Extract message type
        if [[ "$line" == *"ACK:"* ]]; then
            echo -e "${GREEN}✓ Canary acknowledged${NC}"
        elif [[ "$line" == *"APPROVED:"* ]]; then
            echo -e "${GREEN}${BOLD}✅ DEPLOYMENT APPROVED BY CANARY${NC}"
            echo -e "${YELLOW}Safe to deploy to production${NC}"
        elif [[ "$line" == *"REJECTED:"* ]]; then
            echo -e "${RED}${BOLD}❌ DEPLOYMENT REJECTED BY CANARY${NC}"
            echo -e "${RED}Do not deploy to production!${NC}"
        elif [[ "$line" == *"TEST_PASS:"* ]]; then
            echo -e "${GREEN}✓ Test passed: ${line#*TEST_PASS:}${NC}"
        elif [[ "$line" == *"TEST_FAIL:"* ]]; then
            echo -e "${RED}✗ Test failed: ${line#*TEST_FAIL:}${NC}"
        elif [[ "$line" == *"TESTING:"* ]]; then
            echo -e "${YELLOW}⏳ Canary testing in progress...${NC}"
        elif [[ "$line" == *"ALERT:"* ]]; then
            echo -e "${RED}${BOLD}⚠️  CANARY ALERT: ${line#*ALERT:}${NC}"
        else
            echo -e "${BLUE}Canary: ${line#*] - }${NC}"
        fi
    fi
}

# Main monitoring loop
echo -e "${YELLOW}Waiting for Canary instance...${NC}"

while true; do
    # Get last processed line number
    LAST_LINE=$(cat "$LAST_LINE_FILE" 2>/dev/null || echo "0")
    
    # Check for new messages
    if [ -f "$LOG_FILE" ]; then
        CURRENT_LINES=$(wc -l < "$LOG_FILE")
        
        if [ "$CURRENT_LINES" -gt "$LAST_LINE" ]; then
            # Process new lines
            tail -n +$((LAST_LINE + 1)) "$LOG_FILE" | while IFS= read -r line; do
                process_canary_message "$line"
            done
            
            # Update last processed line
            echo "$CURRENT_LINES" > "$LAST_LINE_FILE"
        fi
    fi
    
    sleep 2
done