#!/bin/bash

# AI Infrastructure Startup Script
# Ensures all services start in the correct order with verification

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAX_WAIT_TIME=60  # Maximum seconds to wait for a service
COMPOSE_FILES="-f docker-compose.yaml -f docker-compose.auth.yaml"

# Function to print colored output
print_status() {
    echo -e "$1"
}

# Function to wait for a service to be healthy
wait_for_service() {
    local service=$1
    local check_command=$2
    local wait_time=0
    
    print_status "${YELLOW}⏳ Waiting for $service to be ready...${NC}"
    
    while [[ $wait_time -lt $MAX_WAIT_TIME ]]; do
        if eval "$check_command" > /dev/null 2>&1; then
            print_status "${GREEN}✓ $service is ready${NC}"
            return 0
        fi
        
        sleep 2
        ((wait_time+=2))
        echo -n "."
    done
    
    print_status "${RED}✗ $service failed to start within $MAX_WAIT_TIME seconds${NC}"
    return 1
}

# Main startup sequence
main() {
    print_status "${BLUE}=== Starting AI Infrastructure Services ===${NC}\n"
    
    # Step 1: Check Docker
    print_status "${BLUE}1. Checking Docker...${NC}"
    if ! docker info > /dev/null 2>&1; then
        print_status "${RED}Docker is not running. Please start Docker first.${NC}"
        exit 1
    fi
    print_status "${GREEN}✓ Docker is running${NC}\n"
    
    # Step 2: Check Ollama (host service)
    print_status "${BLUE}2. Checking Ollama...${NC}"
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_status "${YELLOW}⚠ Ollama is not running. Starting Ollama...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            open -a Ollama
            wait_for_service "Ollama" "curl -s http://localhost:11434/api/tags"
        else
            print_status "${RED}Please start Ollama manually${NC}"
            exit 1
        fi
    else
        print_status "${GREEN}✓ Ollama is running${NC}\n"
    fi
    
    # Step 3: Clean up any stuck containers
    print_status "${BLUE}3. Cleaning up...${NC}"
    
    # Check for containers in restart loop
    for container in authelia perplexica; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            local restart_count=$(docker inspect "$container" --format='{{.RestartCount}}' 2>/dev/null || echo "0")
            if [[ $restart_count -gt 5 ]]; then
                print_status "${YELLOW}Container $container has restarted $restart_count times. Resetting...${NC}"
                docker stop "$container" 2>/dev/null || true
                docker rm "$container" 2>/dev/null || true
            fi
        fi
    done
    print_status "${GREEN}✓ Cleanup complete${NC}\n"
    
    # Step 4: Start Redis first (required by Authelia)
    print_status "${BLUE}4. Starting Redis...${NC}"
    docker compose $COMPOSE_FILES up -d redis
    wait_for_service "Redis" "docker exec redis redis-cli ping"
    echo ""
    
    # Step 5: Check and prepare Authelia
    print_status "${BLUE}5. Preparing Authelia...${NC}"
    
    # Check if Authelia database exists and might have encryption issues
    if [[ -f "configs/authelia/db.sqlite3" ]]; then
        # Test if Authelia can start with existing database
        docker compose $COMPOSE_FILES up -d authelia > /dev/null 2>&1
        sleep 3
        
        if docker logs authelia --tail 10 2>&1 | grep -q "encryption key"; then
            print_status "${YELLOW}Detected Authelia encryption key issue. Resetting database...${NC}"
            docker compose $COMPOSE_FILES stop authelia
            
            # Backup and remove corrupted database
            mv configs/authelia/db.sqlite3 "configs/authelia/db.sqlite3.backup-$(date +%Y%m%d-%H%M%S)"
            print_status "${YELLOW}Old database backed up${NC}"
        fi
    fi
    
    # Start Authelia
    docker compose $COMPOSE_FILES up -d authelia
    wait_for_service "Authelia" "curl -s http://localhost:9091/api/health"
    echo ""
    
    # Step 6: Start SearXNG (required by Perplexica)
    print_status "${BLUE}6. Starting SearXNG...${NC}"
    docker compose $COMPOSE_FILES up -d searxng
    wait_for_service "SearXNG" "docker ps --format '{{.Names}}' | grep -q searxng"
    echo ""
    
    # Step 7: Start Perplexica
    print_status "${BLUE}7. Starting Perplexica...${NC}"
    
    # Verify embedding model is configured correctly
    local embedding_model=$(grep "EMBEDDING_MODEL" config/perplexica.host-ollama.toml | cut -d'"' -f2)
    print_status "Checking embedding model: $embedding_model"
    
    if ! curl -s http://localhost:11434/api/tags | grep -q "$embedding_model"; then
        print_status "${YELLOW}Embedding model $embedding_model not found. Using nomic-embed-text:latest${NC}"
        sed -i.bak 's/EMBEDDING_MODEL = .*/EMBEDDING_MODEL = "nomic-embed-text:latest"/' config/perplexica.host-ollama.toml
    fi
    
    docker compose $COMPOSE_FILES up -d perplexica
    wait_for_service "Perplexica" "docker ps --format '{{.Status}}' --filter 'name=perplexica' | grep -q Up"
    echo ""
    
    # Step 8: Start Open WebUI
    print_status "${BLUE}8. Starting Open WebUI...${NC}"
    docker compose $COMPOSE_FILES up -d open-webui
    wait_for_service "Open WebUI" "docker ps --format '{{.Status}}' --filter 'name=open-webui' | grep -q Up"
    echo ""
    
    # Step 9: Start Nginx (must be last)
    print_status "${BLUE}9. Starting Nginx...${NC}"
    docker compose $COMPOSE_FILES up -d nginx
    wait_for_service "Nginx" "curl -s -o /dev/null -w '%{http_code}' http://localhost | grep -q '301'"
    echo ""
    
    # Step 10: Verify all services
    print_status "${BLUE}10. Verifying all services...${NC}"
    ./scripts/health-check.sh
    
    print_status "\n${GREEN}=== All services started successfully! ===${NC}"
    print_status "\nAccess points:"
    print_status "  • Authentication: ${BLUE}https://auth-m4.yourdomain.com${NC}"
    print_status "  • Web UI: ${BLUE}https://webui.yourdomain.com${NC}"
    print_status "  • Perplexica: ${BLUE}https://perplexica.yourdomain.com${NC}"
    
    print_status "\n${YELLOW}Note: Services are protected by Authelia authentication${NC}"
}

# Run main function
main "$@"