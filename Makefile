# ================================================================
#  ricectl — Makefile
# ================================================================

SHELL := /bin/bash
ROOT  := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: help install doctor sync module profile update link test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Full install (interactive profile select)
	@$(ROOT)/ricectl install

install-full: ## Install full profile
	@$(ROOT)/ricectl install --profile=full

install-minimal: ## Install minimal profile
	@$(ROOT)/ricectl install --profile=minimal

install-dev: ## Install dev profile
	@$(ROOT)/ricectl install --profile=dev

install-rice: ## Install rice profile
	@$(ROOT)/ricectl install --profile=rice

dry-run: ## Dry run full profile
	@$(ROOT)/ricectl install --profile=full --dry-run

doctor: ## Run health check
	@$(ROOT)/ricectl doctor

sync: ## Sync dotfiles (push)
	@$(ROOT)/ricectl sync push

pull: ## Pull and apply dotfiles
	@$(ROOT)/ricectl sync pull

update: ## Update system packages
	@$(ROOT)/ricectl update

modules: ## List modules
	@$(ROOT)/ricectl module list

profiles: ## List profiles
	@$(ROOT)/ricectl profile list

secrets-init: ## Initialize secrets with GPG
	@$(ROOT)/ricectl secrets init

backup: ## Create a backup
	@$(ROOT)/ricectl backup create

backup-list: ## List backups
	@$(ROOT)/ricectl backup list

backup-restore: ## Restore latest backup
	@$(ROOT)/ricectl backup restore

link: ## Symlink ricectl to ~/.local/bin
	@mkdir -p $(HOME)/.local/bin
	@ln -sf $(ROOT)/ricectl $(HOME)/.local/bin/ricectl
	@echo "ricectl linked to ~/.local/bin/ricectl"

unlink: ## Remove ricectl symlink
	@rm -f $(HOME)/.local/bin/ricectl
	@echo "ricectl unlinked"

test: ## Smoke test (dry-run + doctor)
	@echo "=== Dry Run Test ==="
	@$(ROOT)/ricectl install --profile=minimal --dry-run
	@echo ""
	@echo "=== Doctor Test ==="
	@$(ROOT)/ricectl doctor
