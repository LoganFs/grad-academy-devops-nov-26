# GTA 6 DevOps Academy — Surviving Launch Day
#
# This Makefile only wraps the long, fiddly commands (k6 load test, curl, log
# tailing). Everything else — `terraform init/apply/destroy`, `ssh`, `docker
# compose` — you run by hand, on purpose, so you learn the real tools.
#
# Endpoint details are auto-resolved from Terraform outputs, or override them:
#   make loadtest URL=http://20.1.2.3
#   make logs     HOST=20.1.2.3

URL     ?= $(shell terraform -chdir=terraform output -raw social_hub_url 2>/dev/null | grep -Eo '^https?://[^[:space:]]+' | head -1)
HOST    ?= $(shell terraform -chdir=terraform output -raw vm_public_ip 2>/dev/null | grep -Eo '^[0-9][0-9.]+' | head -1)
VM_USER ?= rockstar

.DEFAULT_GOAL := help
.PHONY: help loadtest health logs

help: ## Show the wrapped commands
	@echo "Wrapped helpers (everything else is plain terraform / ssh / docker):"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

loadtest: ## Run the k6 "midnight release" spike against the live URL
	k6 run -e TARGET="$(URL)" loadtest/launch-day.js

health: ## Curl the /api/v1/health endpoint
	@curl -s "$(URL)/api/v1/health" && echo

logs: ## Tail the active container logs on the VM (over SSH)
	@ssh $(VM_USER)@$(HOST) -t 'cd /opt/social-hub && f=docker-compose.yml; sudo docker ps --format "{{.Names}}" | grep -q nginx && f=docker-compose.ha.yml; sudo docker compose -f $$f logs -f'
