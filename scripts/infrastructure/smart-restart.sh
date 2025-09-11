#!/bin/bash

# Smart Restart Script for Open WebUI Services
# This script checks if services are running and either restarts them or starts them

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running from correct directory
if [ ! -f "configs/docker-compose.canary.yaml" ]; then
    print_error "Please run this script from the carian-observatory directory"
    exit 1
fi

# Function to check if container is running
is_container_running() {
    local container_name="$1"
    docker ps --format "{{.Names}}" | grep -q "^${container_name}$"
}

# Function to check if container exists (running or stopped)
container_exists() {
    local container_name="$1"
    docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"
}

# Function to get container status
get_container_status() {
    local container_name="$1"
    if is_container_running "$container_name"; then
        echo "running"
    elif container_exists "$container_name"; then
        echo "stopped"
    else
        echo "not_found"
    fi
}

# Function to restart or start canary services
manage_canary_services() {
    print_status "Managing canary services..."
    
    local canary_status=$(get_container_status "open-webui-canary")
    local watchtower_status=$(get_container_status "watchtower-canary")
    
    echo ""
    print_status "Current status:"
    echo "  🐦 Canary: $canary_status"
    echo "  🔄 Watchtower: $watchtower_status"
    echo ""
    
    if [ "$canary_status" = "running" ] || [ "$watchtower_status" = "running" ]; then
        print_status "Services are running - performing restart..."
        docker-compose -f configs/docker-compose.canary.yaml restart
        print_success "Canary services restarted"
    else
        print_status "Services are not running - starting them..."
        docker-compose -f configs/docker-compose.canary.yaml up -d
        print_success "Canary services started"
    fi
}

# Function to manage production services
manage_production_services() {
    print_status "Managing production services..."
    
    local production_status=$(get_container_status "open-webui")
    local perplexica_status=$(get_container_status "perplexica")
    local searxng_status=$(get_container_status "searxng")
    
    echo ""
    print_status "Current status:"
    echo "  🌐 Open WebUI: $production_status"
    echo "  🔍 Perplexica: $perplexica_status"
    echo "  🔎 SearXNG: $searxng_status"
    echo ""
    
    # Check if any production services are running
    local any_running=false
    for service in "open-webui" "perplexica" "searxng"; do
        if is_container_running "$service"; then
            any_running=true
            break
        fi
    done
    
    if [ "$any_running" = true ]; then
        print_status "Production services are running - performing restart..."
        
        # Find the main docker-compose file
        if [ -f "docker-compose.yaml" ]; then
            docker-compose -f docker-compose.yaml restart
        elif [ -f "docker-compose.yml" ]; then
            docker-compose -f docker-compose.yml restart
        else
            print_warning "No main docker-compose file found. Restarting individual containers..."
            for service in "open-webui" "perplexica" "searxng"; do
                if is_container_running "$service"; then
                    docker restart "$service"
                    print_status "Restarted $service"
                fi
            done
        fi
        print_success "Production services restarted"
    else
        print_status "Production services are not running - starting them..."
        
        # Find and start the main docker-compose file
        if [ -f "docker-compose.yaml" ]; then
            docker-compose -f docker-compose.yaml up -d
        elif [ -f "docker-compose.yml" ]; then
            docker-compose -f docker-compose.yml up -d
        else
            print_error "No main docker-compose file found to start production services"
            print_warning "You may need to start them manually"
        fi
        print_success "Production services started"
    fi
}

# Function to check and update hosts file
manage_hosts() {
    print_status "Checking hosts file configuration..."
    
    if [ -f "manage-hosts.sh" ]; then
        ./manage-hosts.sh auto
    else
        print_warning "manage-hosts.sh not found - skipping hosts file update"
    fi
}

# Function to perform health checks
perform_health_checks() {
    print_status "Performing health checks..."
    
    echo ""
    print_status "Waiting for services to start..."
    sleep 5
    
    # Check canary health
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/health | grep -q "200"; then
        print_success "✅ Canary is healthy (port 8081)"
    else
        print_warning "⚠️  Canary health check failed"
    fi
    
    # Check production health (try common ports)
    for port in 8080 3000; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health 2>/dev/null | grep -q "200"; then
            print_success "✅ Service on port $port is healthy"
            break
        elif curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/ 2>/dev/null | grep -q "200"; then
            print_success "✅ Service on port $port is responding"
            break
        fi
    done
}

# Function to show final status
show_final_status() {
    echo ""
    print_status "Final service status:"
    
    # Show docker containers
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(open-webui|perplexica|searxng|watchtower)" || echo "No relevant containers found"
    
    echo ""
    print_status "Access URLs:"
    echo "  🐦 Canary: http://localhost:8081"
    echo "  🌐 Production: http://localhost:8080 (if running)"
    echo "  🔍 Perplexica: http://localhost:3000 (if running)"
    
    # Check hosts file
    if grep -q "webui-m4-canary.yourdomain.com" /etc/hosts 2>/dev/null; then
        echo "  🌍 Canary HTTPS: https://webui-m4-canary.yourdomain.com"
    fi
}

# Function to show usage
show_usage() {
    echo "Smart Restart Script for Open WebUI Services"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  canary      Restart/start only canary services"
    echo "  production  Restart/start only production services"
    echo "  all         Restart/start all services (default)"
    echo "  status      Show current status without changes"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Restart/start all services"
    echo "  $0 canary       # Only manage canary services"
    echo "  $0 production   # Only manage production services"
    echo "  $0 status       # Show status only"
    echo ""
}

# Main script logic
case "${1:-all}" in
    canary)
        manage_canary_services
        manage_hosts
        perform_health_checks
        show_final_status
        ;;
    production)
        manage_production_services
        perform_health_checks
        show_final_status
        ;;
    all)
        manage_production_services
        echo ""
        manage_canary_services
        manage_hosts
        perform_health_checks
        show_final_status
        ;;
    status)
        print_status "Current service status:"
        echo ""
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(open-webui|perplexica|searxng|watchtower)" || echo "No relevant containers found"
        echo ""
        
        # Check hosts file
        print_status "Hosts file entries:"
        grep "webui-m4-canary.yourdomain.com" /etc/hosts 2>/dev/null || echo "  No canary entries found"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown option: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac

print_success "Script completed successfully!"
