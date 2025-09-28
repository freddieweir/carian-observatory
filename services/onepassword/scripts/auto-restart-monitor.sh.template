#!/bin/bash
# 1Password Connect Auto-Restart Monitor
# Watches for container failures and automatically restarts with Touch ID
#
# ⚠️  macOS ONLY - Uses osascript for notifications

set -e

# Check if running on macOS for notification features
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  WARNING: Running on non-macOS system"
    echo "Notifications disabled - monitoring will work but no UI alerts"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_FILE="/tmp/1password-credentials.json"
MONITOR_PID_FILE="/tmp/1password-monitor.pid"
MONITOR_LOG="/tmp/1password-monitor.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$MONITOR_LOG"
}

# Function to check if credentials exist
check_credentials() {
    if [ -f "$CREDENTIALS_FILE" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check container health
check_container_health() {
    local container_name=$1
    local status=$(docker inspect "$container_name" --format='{{.State.Health.Status}}' 2>/dev/null || echo "not_found")
    echo "$status"
}

# Function to trigger restart with Touch ID
trigger_restart() {
    log "Container unhealthy or restarting - triggering Touch ID authentication"

    # Send notification if available (macOS)
    if command -v osascript &> /dev/null; then
        osascript -e 'display notification "1Password Connect needs Touch ID authentication" with title "Container Restart Required" sound name "Ping"'
    fi

    # Stop existing containers cleanly
    log "Stopping containers..."
    cd "$SERVICE_DIR"
    docker compose down 2>/dev/null || true

    # Clean up old credentials
    if [ -f "$CREDENTIALS_FILE" ]; then
        shred -u "$CREDENTIALS_FILE" 2>/dev/null || rm -f "$CREDENTIALS_FILE"
    fi

    # Start with Touch ID
    log "Starting with Touch ID authentication..."
    if "$SCRIPT_DIR/start-with-touchid.sh"; then
        log "✓ Services restarted successfully"
        return 0
    else
        log "✗ Failed to restart services"
        return 1
    fi
}

# Function to monitor containers
monitor_loop() {
    log "Starting 1Password Connect monitor"
    log "Monitoring containers: co-1p-connect-api, co-1p-connect-sync"

    local last_restart_time=0
    local min_restart_interval=30  # Minimum seconds between restart attempts

    while true; do
        # Check both containers
        api_health=$(check_container_health "co-1p-connect-api")
        sync_health=$(check_container_health "co-1p-connect-sync")

        # Check if containers exist
        api_exists=$(docker ps -a --format '{{.Names}}' | grep -c "co-1p-connect-api" || echo 0)
        sync_exists=$(docker ps -a --format '{{.Names}}' | grep -c "co-1p-connect-sync" || echo 0)

        # Determine if restart is needed
        needs_restart=false
        reason=""

        if [ "$api_exists" -eq 0 ] || [ "$sync_exists" -eq 0 ]; then
            if ! check_credentials; then
                needs_restart=true
                reason="Containers not running and no credentials found"
            fi
        elif [ "$api_health" = "unhealthy" ] || [ "$sync_health" = "unhealthy" ]; then
            needs_restart=true
            reason="Container unhealthy (API: $api_health, Sync: $sync_health)"
        elif [ "$api_health" = "not_found" ] || [ "$sync_health" = "not_found" ]; then
            if ! check_credentials; then
                needs_restart=true
                reason="Container not found"
            fi
        fi

        # Check if credentials are missing while containers are running
        if [ "$api_exists" -eq 1 ] && ! check_credentials; then
            needs_restart=true
            reason="Credentials missing while containers running"
        fi

        # Trigger restart if needed (with rate limiting)
        if [ "$needs_restart" = true ]; then
            current_time=$(date +%s)
            time_since_last_restart=$((current_time - last_restart_time))

            if [ $time_since_last_restart -ge $min_restart_interval ]; then
                log "Restart triggered: $reason"
                if trigger_restart; then
                    last_restart_time=$current_time
                else
                    log "Failed to restart - waiting before retry"
                fi
            else
                log "Skipping restart (too soon, waiting $((min_restart_interval - time_since_last_restart))s)"
            fi
        fi

        # Sleep before next check
        sleep 10
    done
}

# Function to start monitor in background
start_background() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        OLD_PID=$(cat "$MONITOR_PID_FILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}Monitor already running with PID $OLD_PID${NC}"
            return 1
        fi
    fi

    echo -e "${GREEN}Starting 1Password Connect monitor in background${NC}"
    nohup "$0" monitor > /dev/null 2>&1 &
    echo $! > "$MONITOR_PID_FILE"
    echo -e "${GREEN}✓ Monitor started with PID $(cat $MONITOR_PID_FILE)${NC}"
    echo -e "Log file: ${CYAN}$MONITOR_LOG${NC}"
}

# Function to stop monitor
stop_background() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        PID=$(cat "$MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}Stopping monitor with PID $PID${NC}"
            kill "$PID"
            rm -f "$MONITOR_PID_FILE"
            echo -e "${GREEN}✓ Monitor stopped${NC}"
        else
            echo -e "${RED}Monitor not running (stale PID file)${NC}"
            rm -f "$MONITOR_PID_FILE"
        fi
    else
        echo -e "${RED}No monitor running${NC}"
    fi
}

# Function to show monitor status
show_status() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        PID=$(cat "$MONITOR_PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Monitor is running${NC}"
            echo "  PID: $PID"
            echo "  Log: $MONITOR_LOG"

            if [ -f "$MONITOR_LOG" ]; then
                echo -e "\n${CYAN}Recent log entries:${NC}"
                tail -5 "$MONITOR_LOG"
            fi
        else
            echo -e "${RED}✗ Monitor not running (stale PID)${NC}"
        fi
    else
        echo -e "${RED}✗ Monitor not running${NC}"
    fi

    echo -e "\n${CYAN}Container Status:${NC}"
    docker ps --filter "name=co-1p-connect" --format "table {{.Names}}\t{{.Status}}"
}

# Main script logic
case "${1:-}" in
    start)
        start_background
        ;;
    stop)
        stop_background
        ;;
    status)
        show_status
        ;;
    monitor)
        monitor_loop
        ;;
    logs)
        if [ -f "$MONITOR_LOG" ]; then
            tail -f "$MONITOR_LOG"
        else
            echo -e "${RED}No log file found${NC}"
        fi
        ;;
    *)
        echo -e "${CYAN}1Password Connect Auto-Restart Monitor${NC}"
        echo -e "${YELLOW}Usage: $0 {start|stop|status|logs}${NC}"
        echo ""
        echo "Commands:"
        echo "  start   - Start monitor in background"
        echo "  stop    - Stop background monitor"
        echo "  status  - Show monitor and container status"
        echo "  logs    - Follow monitor logs"
        exit 1
        ;;
esac