#!/bin/bash

# AI Infrastructure Health Check Script
# Monitors all critical services and reports issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/ai-infra-health-$(date +%Y%m%d).log"
ALERT_FILE="/tmp/ai-infra-alerts.txt"
SERVICES_TO_CHECK=("co-nginx" "co-authelia" "co-perplexica" "co-open-webui" "co-redis" "co-searxng")

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Function to send alert (can be extended to send notifications)
send_alert() {
    local service=$1
    local issue=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $service - $issue" >> "$ALERT_FILE"
    log_message "${RED}⚠️  ALERT: $service - $issue${NC}"
}

# Check if a container is running
check_container() {
    local container=$1
    
    # Check if container exists and is running
    if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
        # Container is running, check if it's healthy
        local status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-health-check")
        
        if [[ "$status" == "healthy" ]] || [[ "$status" == "no-health-check" ]]; then
            log_message "${GREEN}✓ $container is running${NC}"
            return 0
        else
            send_alert "$container" "Container is running but unhealthy (status: $status)"
            return 1
        fi
    else
        # Check if container exists but is stopped
        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
            send_alert "$container" "Container is stopped"
            
            # Try to start the container
            log_message "${YELLOW}Attempting to start $container...${NC}"
            if docker start "$container" 2>/dev/null; then
                sleep 5
                log_message "${GREEN}✓ Successfully started $container${NC}"
                return 0
            else
                send_alert "$container" "Failed to start container"
                return 1
            fi
        else
            send_alert "$container" "Container does not exist"
            return 1
        fi
    fi
}

# Check HTTP endpoint
check_endpoint() {
    local url=$1
    local expected_code=$2
    local service=$3
    
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 5 || echo "000")
    
    if [[ "$response_code" == "$expected_code" ]]; then
        log_message "${GREEN}✓ $service endpoint is responding correctly (HTTP $response_code)${NC}"
        return 0
    else
        send_alert "$service" "Endpoint returned HTTP $response_code (expected $expected_code)"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    local threshold=90
    local usage=$(df -h / | awk 'NR==2 {print int($5)}')
    
    if [[ $usage -ge $threshold ]]; then
        send_alert "Disk Space" "Usage at ${usage}% (threshold: ${threshold}%)"
        return 1
    else
        log_message "${GREEN}✓ Disk space usage: ${usage}%${NC}"
        return 0
    fi
}

# Check memory usage
check_memory() {
    local threshold=90
    
    # Handle macOS vs Linux differences
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use vm_stat
        local pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        local pages_total=$(vm_stat | grep "Pages active\|Pages inactive\|Pages speculative\|Pages wired\|Pages free" | awk '{sum+=$NF} END {print sum}' | sed 's/\.//')
        if [[ -n "$pages_total" ]] && [[ "$pages_total" -gt 0 ]]; then
            local usage=$((100 - (pages_free * 100 / pages_total)))
        else
            local usage=0
        fi
    else
        # Linux - use free command
        local usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    fi
    
    if [[ $usage -ge $threshold ]]; then
        send_alert "Memory" "Usage at ${usage}% (threshold: ${threshold}%)"
        return 1
    else
        log_message "${GREEN}✓ Memory usage: ${usage}%${NC}"
        return 0
    fi
}

# Check Authelia specific issues
check_authelia() {
    # Check for encryption key issues
    local authelia_logs=$(docker logs authelia --tail 50 2>&1 | grep -i "encryption key" || true)
    
    if [[ -n "$authelia_logs" ]]; then
        send_alert "Authelia" "Encryption key mismatch detected"
        
        # Attempt auto-recovery if database is corrupted
        log_message "${YELLOW}Attempting Authelia recovery...${NC}"
        docker stop authelia 2>/dev/null || true
        
        # Backup existing database
        if [[ -f "configs/authelia/db.sqlite3" ]]; then
            cp configs/authelia/db.sqlite3 "configs/authelia/db.sqlite3.backup-$(date +%Y%m%d-%H%M%S)"
            rm configs/authelia/db.sqlite3
        fi
        
        # Restart with fresh database
        docker compose -f docker-compose.auth.yaml up -d authelia
        sleep 5
        
        # Verify recovery
        if check_endpoint "http://localhost:9091/api/health" "200" "Authelia"; then
            log_message "${GREEN}✓ Authelia recovered successfully${NC}"
            return 0
        else
            return 1
        fi
    fi
    
    return 0
}

# Check Perplexica embedding model
check_perplexica_embeddings() {
    # Check for embedding errors in logs
    local embedding_errors=$(docker logs perplexica --tail 50 2>&1 | grep -i "does not support embeddings" || true)
    
    if [[ -n "$embedding_errors" ]]; then
        send_alert "Perplexica" "Embedding model error detected"
        
        # Check if nomic-embed-text model is available
        local has_nomic=$(curl -s http://localhost:11434/api/tags | grep -o "nomic-embed-text:latest" || true)
        
        if [[ -z "$has_nomic" ]]; then
            log_message "${YELLOW}Installing nomic-embed-text model...${NC}"
            curl -X POST http://localhost:11434/api/pull -d '{"name": "nomic-embed-text:latest"}'
        fi
        
        # Update configuration if needed
        sed -i.bak 's/EMBEDDING_MODEL = .*/EMBEDDING_MODEL = "nomic-embed-text:latest"/' config/perplexica.host-ollama.toml
        
        # Restart Perplexica
        docker restart perplexica
        sleep 5
        
        log_message "${GREEN}✓ Perplexica embedding configuration updated${NC}"
        return 0
    fi
    
    return 0
}

# Main health check
main() {
    log_message "=== Starting AI Infrastructure Health Check ==="
    
    local errors=0
    
    # System checks
    log_message "\n📊 System Health:"
    check_disk_space || ((errors++))
    check_memory || ((errors++))
    
    # Container checks
    log_message "\n🐳 Container Status:"
    for service in "${SERVICES_TO_CHECK[@]}"; do
        check_container "$service" || ((errors++))
    done
    
    # Service-specific checks
    log_message "\n🔍 Service Health:"
    
    # Authelia health
    if docker ps --format "{{.Names}}" | grep -q "co-authelia"; then
        check_endpoint "http://localhost:9091/api/health" "200" "Authelia" || ((errors++))
        check_authelia || ((errors++))
    fi
    
    # Perplexica health  
    if docker ps --format "{{.Names}}" | grep -q "co-perplexica"; then
        check_perplexica_embeddings || ((errors++))
    fi
    
    # Redis health
    if docker ps --format "{{.Names}}" | grep -q "co-redis"; then
        docker exec co-redis redis-cli ping > /dev/null 2>&1 || {
            send_alert "Redis" "Cannot ping Redis server"
            ((errors++))
        }
    fi
    
    # Report summary
    log_message "\n📋 Health Check Summary:"
    if [[ $errors -eq 0 ]]; then
        log_message "${GREEN}✅ All systems operational${NC}"
    else
        log_message "${RED}❌ Found $errors issue(s) - check $ALERT_FILE for details${NC}"
        
        # Display recent alerts
        if [[ -f "$ALERT_FILE" ]]; then
            log_message "\n📨 Recent Alerts:"
            tail -5 "$ALERT_FILE"
        fi
    fi
    
    log_message "=== Health Check Complete ==="
    
    exit $errors
}

# Run main function
main "$@"