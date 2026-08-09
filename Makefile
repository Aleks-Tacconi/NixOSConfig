.PHONY: rebuild git update clean all

GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m  # No Color

GIT_ADD := git add -A
ULIMIT := ulimit -n 50000
REBUILD := sudo nixos-rebuild switch --flake

MSG ?= new version

rebuild:
	@echo ""
	@if [ -z "$(NIXOS_HOST)" ]; then \
		echo -e "$(YELLOW)==> NIXOS_HOST is not set; activate this host's configuration first.$(NC)"; \
		exit 1; \
	fi

	@if [ "$(NIXOS_HOST)" = "laptop" ] && ! mountpoint -q /boot; then \
		echo -e "$(YELLOW)==> Mounting /boot...$(NC)"; \
		sudo mount /dev/nvme0n1p1 /boot; \
		echo -e "$(GREEN)/boot mounted$(NC)"; \
	fi

	@echo ""
	@echo -e "$(YELLOW)==> Staging changes for git...$(NC)"
	$(GIT_ADD)

	@echo ""
	@echo -e "$(YELLOW)==> Rebuilding NixOS configuration for $(NIXOS_HOST)...$(NC)"
	$(ULIMIT) && $(REBUILD) ".#$(NIXOS_HOST)"

	@echo ""
	@echo -e "$(GREEN)==> $(NIXOS_HOST) rebuild complete!$(NC)"
	@echo ""

git:
	@echo ""
	@echo -e "$(YELLOW)==> Staging all changes...$(NC)"
	$(GIT_ADD)

	@echo ""
	@echo -e "$(YELLOW)==> Committing changes with message: $(MSG)$(NC)"
	git commit -m "$(MSG)"

	@echo ""
	@echo -e "$(YELLOW)==> Pushing changes to origin/main...$(NC)"
	git push origin main

	@echo ""
	@echo -e "$(GREEN)==> Git push complete!$(NC)"
	@echo ""

update:
	@echo ""
	@echo -e "$(YELLOW)==> Updating nix flake...$(NC)"
	nix flake update
	
	@echo ""
	@echo -e "$(GREEN)==> Flake update complete!$(NC)"
	@echo ""

clean:
	@echo ""
	@echo -e "$(YELLOW)==> Wiping user profiles...$(NC)"
	nix profile wipe-history

	@echo ""
	@echo -e "$(YELLOW)==> Wiping system profiles older than 1 day...$(NC)"
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 1d

	@echo ""
	@echo -e "$(YELLOW)==> Collecting garbage...$(NC)"
	sudo nix-collect-garbage -d
	nix-collect-garbage -d

	@echo ""
	@echo -e "$(GREEN)==> Clean complete!$(NC)"
	@echo ""

all: update git rebuild
	@echo ""
	@echo -e "$(GREEN)==> All tasks complete!$(NC)"
	@echo ""
