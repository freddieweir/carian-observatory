#!/bin/bash

# Quick Setup Script for Ollama-WebUI-Nginx-Perplexica
# Detects machine type and provides appropriate setup guidance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art Header
echo -e "${BLUE}"
cat << "EOF"
 ╔═══════════════════════════════════════════════════════════════╗
 ║                                                               ║
 ║   ██████╗ ██╗     ██╗      █████╗ ███╗   ███╗ █████╗         ║
 ║  ██╔═══██╗██║     ██║     ██╔══██╗████╗ ████║██╔══██╗        ║
 ║  ██║   ██║██║     ██║     ███████║██╔████╔██║███████║        ║
 ║  ██║   ██║██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║        ║
 ║  ╚██████╔╝███████╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║        ║
 ║   ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝        ║
 ║                                                               ║
 ║           WebUI + Nginx + Perplexica Stack Setup             ║
 ║                                                               ║
 ╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Function to detect machine type
detect_machine() {
    local model=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}' | xargs)
    local chip=$(system_profiler SPHardwareDataType | grep "Chip" | awk -F': ' '{print $2}' | xargs)
    local memory=$(system_profiler SPHardwareDataType | grep "Memory" | awk -F': ' '{print $2}' | xargs)
    
    echo -e "${CYAN}🖥️  Machine Detection:${NC}"
    echo -e "   Model: ${GREEN}$model${NC}"
    echo -e "   Chip: ${GREEN}$chip${NC}"
    echo -e "   Memory: ${GREEN}$memory${NC}"
    
    # Determine machine type based on model and specs
    if [[ "$model" == *"Mac mini"* ]]; then
        echo "mini"
    elif [[ "$model" == *"MacBook Pro"* ]] && [[ "$chip" == *"M4"* ]]; then
        echo "m4"
    elif [[ "$model" == *"MacBook Air"* ]] && [[ "$chip" == *"M2"* ]]; then
        echo "m2"
    elif [[ "$model" == *"MacBook Pro"* ]] && [[ "$chip" == *"M2"* ]]; then
        echo "m2"
    else
        echo "unknown"
    fi
}

# Function to get local IP
get_local_ip() {
    local ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
    echo "$ip"
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "\n${YELLOW}🔍 Checking Prerequisites...${NC}"
    
    # Check Docker
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker found${NC}"
    else
        echo -e "${RED}❌ Docker not found. Please install Docker Desktop.${NC}"
        exit 1
    fi
    
    # Check Docker Compose
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✅ Docker Compose found${NC}"
    else
        echo -e "${RED}❌ Docker Compose not found. Please update Docker Desktop.${NC}"
        exit 1
    fi
    
    # Check OpenSSL
    if command -v openssl &> /dev/null; then
        echo -e "${GREEN}✅ OpenSSL found${NC}"
    else
        echo -e "${RED}❌ OpenSSL not found. Please install OpenSSL.${NC}"
        exit 1
    fi
}

# Function to show domain mapping
show_domain_mapping() {
    local machine_type=$1
    local ip=$2
    
    echo -e "\n${PURPLE}🌐 Domain Mapping for Your Machine:${NC}"
    echo -e "${PURPLE}===================================${NC}"
    
    case $machine_type in
        "mini")
            echo -e "${GREEN}• webui.yourdomain.com → $ip${NC}"
            echo -e "${GREEN}• perplexica.yourdomain.com → $ip${NC}"
            ;;
        "m4")
            echo -e "${GREEN}• webui-m4.yourdomain.com → $ip${NC}"
            echo -e "${GREEN}• perplexica-m4.yourdomain.com → $ip${NC}"
            ;;
        "m2")
            echo -e "${GREEN}• webui-m2.yourdomain.com → $ip${NC}"
            echo -e "${GREEN}• perplexica-m2.yourdomain.com → $ip${NC}"
            ;;
        *)
            echo -e "${YELLOW}• webui.yourdomain.com → $ip${NC}"
            echo -e "${YELLOW}• perplexica.yourdomain.com → $ip${NC}"
            echo -e "${YELLOW}  (Using default domains - you may want to customize)${NC}"
            ;;
    esac
}

# Function to show setup options
show_setup_options() {
    echo -e "\n${CYAN}🚀 Setup Options:${NC}"
    echo -e "${CYAN}=================${NC}"
    echo -e "${GREEN}1.${NC} ${YELLOW}HTTPS Setup${NC} (Recommended for production)"
    echo -e "   • Generates SSL certificates"
    echo -e "   • Requires DNS configuration"
    echo -e "   • Full security setup"
    echo -e ""
    echo -e "${GREEN}2.${NC} ${YELLOW}HTTP Setup${NC} (Quick testing)"
    echo -e "   • No SSL certificates needed"
    echo -e "   • Access via IP address"
    echo -e "   • Faster to get started"
    echo -e ""
    echo -e "${GREEN}3.${NC} ${YELLOW}Show Instructions Only${NC}"
    echo -e "   • Display setup guide"
    echo -e "   • No automatic setup"
}

# Main setup function
main() {
    echo -e "${BLUE}🎯 Starting Ollama-WebUI-Nginx-Perplexica Setup${NC}"
    
    # Check prerequisites
    check_prerequisites
    
    # Detect machine
    local machine_type=$(detect_machine)
    local local_ip=$(get_local_ip)
    
    echo -e "\n${CYAN}📍 Detected Configuration:${NC}"
    echo -e "   Machine Type: ${GREEN}$machine_type${NC}"
    echo -e "   Local IP: ${GREEN}$local_ip${NC}"
    
    # Show domain mapping
    show_domain_mapping "$machine_type" "$local_ip"
    
    # Show setup options
    show_setup_options
    
    # Get user choice
    echo -e "\n${YELLOW}Please choose an option (1-3):${NC} "
    read -r choice
    
    case $choice in
        1)
            echo -e "\n${GREEN}🔐 Setting up HTTPS configuration...${NC}"
            
            # Generate SSL certificates
            echo -e "${YELLOW}📜 Generating SSL certificates...${NC}"
            if ./setup-ssl.sh; then
                echo -e "${GREEN}✅ SSL certificates generated successfully${NC}"
            else
                echo -e "${RED}❌ Failed to generate SSL certificates${NC}"
                exit 1
            fi
            
            # Start services
            echo -e "${YELLOW}🚀 Starting services with HTTPS...${NC}"
            if docker compose up -d; then
                echo -e "${GREEN}✅ Services started successfully${NC}"
                echo -e "\n${PURPLE}🎉 Setup Complete!${NC}"
                echo -e "${PURPLE}Access your services at:${NC}"
                case $machine_type in
                    "mini")
                        echo -e "   • ${GREEN}https://webui.yourdomain.com${NC}"
                        echo -e "   • ${GREEN}https://perplexica.yourdomain.com${NC}"
                        ;;
                    "m4")
                        echo -e "   • ${GREEN}https://webui-m4.yourdomain.com${NC}"
                        echo -e "   • ${GREEN}https://perplexica-m4.yourdomain.com${NC}"
                        ;;
                    "m2")
                        echo -e "   • ${GREEN}https://webui-m2.yourdomain.com${NC}"
                        echo -e "   • ${GREEN}https://perplexica-m2.yourdomain.com${NC}"
                        ;;
                esac
                echo -e "\n${YELLOW}📱 Next Steps:${NC}"
                echo -e "   1. For Mac access: Add entries to /etc/hosts (see README.md)"
                echo -e "   2. For iOS access: Use IP-based URLs or /etc/hosts"
                echo -e "   3. Trust certificates on iOS devices"
                echo -e "   4. See README.md for detailed DNS setup options"
            else
                echo -e "${RED}❌ Failed to start services${NC}"
                exit 1
            fi
            ;;
        2)
            echo -e "\n${GREEN}🌐 Setting up HTTP configuration...${NC}"
            
            # Start services with HTTP
            echo -e "${YELLOW}🚀 Starting services with HTTP...${NC}"
            if docker compose -f docker-compose.simple.yaml up -d; then
                echo -e "${GREEN}✅ Services started successfully${NC}"
                echo -e "\n${PURPLE}🎉 Setup Complete!${NC}"
                echo -e "${PURPLE}Access your services at:${NC}"
                echo -e "   • ${GREEN}http://$local_ip${NC} (Open-WebUI)"
                echo -e "   • ${GREEN}http://$local_ip/perplexica/${NC} (Perplexica)"
                echo -e "\n${YELLOW}💡 To upgrade to HTTPS later:${NC}"
                echo -e "   1. Stop services: ${CYAN}docker compose down${NC}"
                echo -e "   2. Run: ${CYAN}./setup-ssl.sh${NC}"
                echo -e "   3. Start with HTTPS: ${CYAN}docker compose up -d${NC}"
            else
                echo -e "${RED}❌ Failed to start services${NC}"
                exit 1
            fi
            ;;
        3)
            echo -e "\n${GREEN}📖 Setup Instructions${NC}"
            echo -e "${GREEN}===================${NC}"
            echo -e "\n${YELLOW}For HTTPS Setup:${NC}"
            echo -e "1. Run: ${CYAN}./setup-ssl.sh${NC}"
            echo -e "2. Configure DNS in Eero app"
            echo -e "3. Run: ${CYAN}docker compose up -d${NC}"
            echo -e "\n${YELLOW}For HTTP Setup:${NC}"
            echo -e "1. Run: ${CYAN}docker compose -f docker-compose.simple.yaml up -d${NC}"
            echo -e "2. Access via IP: ${CYAN}http://$local_ip${NC}"
            echo -e "\n${YELLOW}For detailed instructions, see:${NC} ${CYAN}README.md${NC}"
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please run the script again.${NC}"
            exit 1
            ;;
    esac
    
    echo -e "\n${BLUE}📚 For more information, check the README.md file${NC}"
    echo -e "${BLUE}🆘 If you need help, create an issue in the repository${NC}"
}

# Run main function
main "$@"
