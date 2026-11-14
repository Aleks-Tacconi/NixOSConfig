.DEFAULT_GOAL := help
.PHONY: help rebuild dry-run check fmt lint git update clean all

GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m  # No Color

GIT_ADD := git add -A
ULIMIT := ulimit -n 50000
REBUILD := sudo nixos-rebuild switch --flake

MSG ?= new version

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  $(GREEN)%-12s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

rebuild: ## Rebuild NixOS configuration for $(NIXOS_HOST)
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

dry-run: ## Dry-run build for $(NIXOS_HOST)
	@if [ -z "$(NIXOS_HOST)" ]; then \
		echo -e "$(YELLOW)==> NIXOS_HOST is not set; activate this host's configuration first.$(NC)"; \
		exit 1; \
	fi
	nix build ".#nixosConfigurations.$(NIXOS_HOST).config.system.build.toplevel" --dry-run

check: ## Evaluate the flake and run checks
	nix flake check

fmt: ## Check Nix formatting with nixfmt-rfc-style
	nix run nixpkgs#nixfmt-rfc-style -- -c $$(git ls-files '*.nix')

lint: ## Run Nix, Python, shell, and QML linters and tests
	nix run nixpkgs#nixfmt-rfc-style -- -c configuration/applications/quickshell/*.nix
	nix run nixpkgs#statix -- check configuration/applications/quickshell
	nix run nixpkgs#ruff -- check \
		configuration/applications/quickshell \
		configuration/homemanagerconfig/wallpaper_theme.py
	nix run nixpkgs#mypy -- --strict --ignore-missing-imports \
		configuration/applications/quickshell/gtk-actions.py \
		configuration/applications/quickshell/qt-menu.py \
		configuration/applications/quickshell/network_control.py \
		configuration/applications/quickshell/network_control_test.py \
		configuration/homemanagerconfig/wallpaper_theme.py
	nix run nixpkgs#python3 -- -m unittest discover -s configuration/applications/quickshell -p '*_test.py'
	@sh_files="$$(git ls-files '*.sh')"; \
	if [ -n "$$sh_files" ]; then \
		nix run nixpkgs#shellcheck -- $$sh_files; \
	fi
	@qs_wrapped="$$(nix eval --raw '.#nixosConfigurations.laptop.config.home-manager.users.aleks.home.packages' --apply 'pkgs: (builtins.head (builtins.filter (p: (p.pname or "") == "quickshell-wrapper") pkgs)).wrapped.outPath')"; \
	qt_dec="$$(nix eval --raw nixpkgs#qt6.qtdeclarative.outPath)"; \
	qt_5c="$$(nix eval --raw nixpkgs#qt6.qt5compat.outPath)"; \
	"$$qt_dec/bin/qmllint" \
		-I "$$qt_dec/lib/qt-6/qml" \
		-I "$$qt_5c/lib/qt-6/qml" \
		-I "$$qs_wrapped/lib/qt-6/qml" \
		-I configuration/applications/quickshell/config/minimal \
		$$(find configuration/applications/quickshell/config/minimal -name 'qmldir' -printf '-i %p ') \
		$$(find configuration/applications/quickshell/config/minimal -name '*.qml' | sort)

git: ## Stage, commit (MSG="..."), and push to origin/main
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

update: ## Update all flake inputs
	@echo ""
	@echo -e "$(YELLOW)==> Updating nix flake...$(NC)"
	nix flake update
	
	@echo ""
	@echo -e "$(GREEN)==> Flake update complete!$(NC)"
	@echo ""

clean: ## Wipe old profile history and collect garbage
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

all: update git rebuild ## Update flake, commit/push (MSG="..."), and rebuild $(NIXOS_HOST)
	@echo ""
	@echo -e "$(GREEN)==> All tasks complete!$(NC)"
	@echo ""
