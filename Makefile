.PHONY: help setup start stop restart status logs clean test lint validate backup restore update config health

# Default target - show help
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

##@ General

help: ## Display this help message
	@echo "$(BLUE)Carian Observatory - Makefile Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup & Configuration

setup: ## Initial setup - create .env from template and generate configs
	@echo "$(BLUE)Setting up Carian Observatory...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)✓$(NC) Created .env file from template"; \
		echo "$(YELLOW)⚠$(NC)  Please edit .env with your configuration before proceeding"; \
	else \
		echo "$(YELLOW)⚠$(NC)  .env already exists, skipping..."; \
	fi

config: ## Generate all configuration files from templates
	@echo "$(BLUE)Generating configuration files from templates...$(NC)"
	@./scripts/create-all-from-templates.sh
	@echo "$(GREEN)✓$(NC) Configuration files generated"

validate: ## Validate Docker Compose configuration
	@echo "$(BLUE)Validating Docker Compose configuration...$(NC)"
	@docker compose config > /dev/null && echo "$(GREEN)✓$(NC) Docker Compose configuration is valid" || echo "$(RED)✗$(NC) Docker Compose configuration is invalid"

env-check: ## Check that required environment variables are set
	@echo "$(BLUE)Checking required environment variables...$(NC)"
	@./scripts/validate-env.sh 2>/dev/null || echo "$(YELLOW)⚠$(NC)  Some environment variables may be missing"

##@ Service Management

start: ## Start all services
	@echo "$(BLUE)Starting all services...$(NC)"
	@docker compose up -d
	@echo "$(GREEN)✓$(NC) Services started"
	@make status

stop: ## Stop all services
	@echo "$(BLUE)Stopping all services...$(NC)"
	@docker compose down
	@echo "$(GREEN)✓$(NC) Services stopped"

restart: ## Restart all services
	@echo "$(BLUE)Restarting all services...$(NC)"
	@docker compose restart
	@echo "$(GREEN)✓$(NC) Services restarted"

status: ## Show service status
	@echo "$(BLUE)Service Status:$(NC)"
	@docker compose ps

##@ Logs & Monitoring

logs: ## Show logs for all services (use SERVICE=name for specific service)
	@if [ -n "$(SERVICE)" ]; then \
		echo "$(BLUE)Showing logs for $(SERVICE)...$(NC)"; \
		docker compose logs -f $(SERVICE); \
	else \
		echo "$(BLUE)Showing logs for all services...$(NC)"; \
		docker compose logs -f; \
	fi

logs-tail: ## Tail logs (last 100 lines)
	@docker compose logs --tail=100 -f

health: ## Check health status of all services
	@echo "$(BLUE)Health Status:$(NC)"
	@for service in $$(docker compose ps --services); do \
		health=$$(docker inspect --format='{{.State.Health.Status}}' co-$$service 2>/dev/null || echo "no healthcheck"); \
		if [ "$$health" = "healthy" ]; then \
			echo "  $(GREEN)✓$(NC) $$service: $$health"; \
		elif [ "$$health" = "no healthcheck" ]; then \
			echo "  $(YELLOW)⚠$(NC) $$service: $$health"; \
		else \
			echo "  $(RED)✗$(NC) $$service: $$health"; \
		fi; \
	done

##@ Testing & Validation

test: ## Run all tests
	@echo "$(BLUE)Running test suite...$(NC)"
	@./tests/run_all_tests.sh

test-unit: ## Run unit tests only
	@echo "$(BLUE)Running unit tests...$(NC)"
	@./tests/unit/test_template_generation.sh

test-integration: ## Run integration tests only
	@echo "$(BLUE)Running integration tests...$(NC)"
	@./tests/integration/test_docker_compose.sh

lint: ## Lint shell scripts and YAML files
	@echo "$(BLUE)Linting shell scripts...$(NC)"
	@find . -name "*.sh" -not -path "*/\.*" -type f -exec shellcheck {} + 2>/dev/null || echo "$(YELLOW)⚠$(NC)  shellcheck not installed or errors found"
	@echo "$(BLUE)Linting YAML files...$(NC)"
	@yamllint . 2>/dev/null || echo "$(YELLOW)⚠$(NC)  yamllint not installed or errors found"

security-scan: ## Run security scans (gitleaks, trivy)
	@echo "$(BLUE)Running security scans...$(NC)"
	@echo "$(BLUE)Checking for secrets with gitleaks...$(NC)"
	@gitleaks detect --verbose 2>/dev/null || echo "$(YELLOW)⚠$(NC)  gitleaks not installed"
	@echo "$(BLUE)Scanning for vulnerabilities with trivy...$(NC)"
	@trivy fs . 2>/dev/null || echo "$(YELLOW)⚠$(NC)  trivy not installed"

##@ Maintenance

update: ## Pull latest images and restart services
	@echo "$(BLUE)Updating Docker images...$(NC)"
	@docker compose pull
	@echo "$(GREEN)✓$(NC) Images updated"
	@make restart

clean: ## Remove stopped containers and unused images
	@echo "$(BLUE)Cleaning up Docker resources...$(NC)"
	@docker compose down --remove-orphans
	@docker system prune -f
	@echo "$(GREEN)✓$(NC) Cleanup complete"

clean-all: ## Remove all containers, volumes, and images (DESTRUCTIVE!)
	@echo "$(RED)WARNING: This will remove all containers, volumes, and images!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		docker system prune -a -f --volumes; \
		echo "$(GREEN)✓$(NC) All resources removed"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

##@ Backup & Restore

backup: ## Backup all service data and configurations
	@echo "$(BLUE)Creating backup...$(NC)"
	@mkdir -p backups
	@tar -czf backups/carian-observatory-backup-$$(date +%Y%m%d-%H%M%S).tar.gz \
		services/*/data \
		services/*/configs \
		.env \
		2>/dev/null || true
	@echo "$(GREEN)✓$(NC) Backup created in backups/ directory"

restore: ## Restore from backup (use BACKUP=filename)
	@if [ -z "$(BACKUP)" ]; then \
		echo "$(RED)Error: Please specify BACKUP=filename$(NC)"; \
		echo "Available backups:"; \
		ls -1 backups/*.tar.gz 2>/dev/null || echo "  No backups found"; \
		exit 1; \
	fi
	@echo "$(BLUE)Restoring from $(BACKUP)...$(NC)"
	@make stop
	@tar -xzf backups/$(BACKUP)
	@make start
	@echo "$(GREEN)✓$(NC) Restore complete"

##@ Development

dev-setup: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@pip install pre-commit 2>/dev/null || echo "$(YELLOW)⚠$(NC)  pip not available, skipping pre-commit"
	@pre-commit install 2>/dev/null || echo "$(YELLOW)⚠$(NC)  pre-commit not installed"
	@echo "$(GREEN)✓$(NC) Development environment ready"

format: ## Format shell scripts (requires shfmt)
	@echo "$(BLUE)Formatting shell scripts...$(NC)"
	@find . -name "*.sh" -not -path "*/\.*" -type f -exec shfmt -w {} + 2>/dev/null || echo "$(YELLOW)⚠$(NC)  shfmt not installed"
	@echo "$(GREEN)✓$(NC) Formatting complete"

##@ Service-Specific

authelia-logs: ## Show Authelia logs
	@docker compose logs -f co-authelia-service co-authelia-redis

nginx-logs: ## Show Nginx logs
	@docker compose logs -f co-nginx-service

nginx-reload: ## Reload Nginx configuration without restart
	@echo "$(BLUE)Reloading Nginx configuration...$(NC)"
	@docker exec co-nginx-service nginx -s reload
	@echo "$(GREEN)✓$(NC) Nginx reloaded"

webui-logs: ## Show Open-WebUI logs
	@docker compose logs -f co-open-webui-service

monitoring-logs: ## Show monitoring stack logs (Prometheus, Grafana, Loki)
	@docker compose logs -f co-prometheus co-grafana co-loki

##@ Utilities

shell: ## Open shell in service container (use SERVICE=name)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: Please specify SERVICE=name$(NC)"; \
		docker compose ps --services; \
		exit 1; \
	fi
	@echo "$(BLUE)Opening shell in $(SERVICE)...$(NC)"
	@docker exec -it co-$(SERVICE) /bin/sh || docker exec -it co-$(SERVICE) /bin/bash

exec: ## Execute command in service (use SERVICE=name CMD="command")
	@if [ -z "$(SERVICE)" ] || [ -z "$(CMD)" ]; then \
		echo "$(RED)Error: Please specify SERVICE=name and CMD=\"command\"$(NC)"; \
		exit 1; \
	fi
	@docker exec co-$(SERVICE) $(CMD)

ps: ## Show running containers with resource usage
	@docker stats --no-stream $$(docker compose ps -q)

networks: ## Show Docker networks
	@docker network ls | grep carian-observatory

volumes: ## Show Docker volumes
	@docker volume ls | grep carian-observatory

##@ Information

info: ## Display system information and versions
	@echo "$(BLUE)System Information:$(NC)"
	@echo "  Docker: $$(docker --version)"
	@echo "  Docker Compose: $$(docker compose version)"
	@echo "  Services: $$(docker compose ps --services | wc -l)"
	@echo "  Running: $$(docker compose ps --services --filter status=running | wc -l)"
	@echo "  Stopped: $$(docker compose ps --services --filter status=stopped 2>/dev/null | wc -l)"

urls: ## Display service URLs
	@echo "$(BLUE)Service URLs (replace with your domain):$(NC)"
	@echo "  Open-WebUI:  https://chat.yourdomain.com"
	@echo "  Perplexica:  https://search.yourdomain.com"
	@echo "  Authelia:    https://auth.yourdomain.com"
	@echo "  Grafana:     https://grafana.yourdomain.com"
	@echo "  Prometheus:  https://prometheus.yourdomain.com"

version: ## Display project version
	@echo "$(BLUE)Carian Observatory$(NC)"
	@git describe --tags 2>/dev/null || echo "Version: Development"
	@echo "Branch: $$(git branch --show-current)"
	@echo "Commit: $$(git rev-parse --short HEAD)"
