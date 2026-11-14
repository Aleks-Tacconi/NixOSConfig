.DEFAULT_GOAL := help
.PHONY: help rebuild dry-run check fmt lint git update clean all

BLUE   := \033[0;34m
CYAN   := \033[0;36m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m

LOG_INFO  = printf "$(CYAN)[INFO]$(NC)  %s\n"
LOG_EXEC  = printf "$(YELLOW)[EXEC]$(NC)  %s\n"
LOG_OK    = printf "$(GREEN)[OK]$(NC)    %s\n"
LOG_ERROR = printf "$(RED)[ERROR]$(NC) %s\n" >&2

GIT_ADD := git add -A
ULIMIT := ulimit -n 50000
REBUILD := sudo nixos-rebuild switch --flake

MSG ?= new version

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  $(GREEN)%-12s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

rebuild: ## Rebuild NixOS configuration for $(NIXOS_HOST)
	@if [ -z "$(NIXOS_HOST)" ]; then \
		$(LOG_ERROR) "NIXOS_HOST is not set; activate this host's configuration first."; \
		exit 1; \
	fi
	@if [ "$(NIXOS_HOST)" = "laptop" ] && ! mountpoint -q /boot; then \
		$(LOG_INFO) "Mounting /boot..."; \
		$(LOG_EXEC) "sudo mount /dev/nvme0n1p1 /boot"; \
		sudo mount /dev/nvme0n1p1 /boot; \
		$(LOG_OK) "/boot mounted"; \
	fi
	@$(LOG_INFO) "Staging changes for git..."
	@$(LOG_EXEC) "$(GIT_ADD)"
	@$(GIT_ADD)
	@$(LOG_INFO) "Rebuilding NixOS configuration for $(NIXOS_HOST)..."
	@$(LOG_EXEC) "$(REBUILD) .#$(NIXOS_HOST)"
	@$(ULIMIT) && $(REBUILD) ".#$(NIXOS_HOST)"
	@$(LOG_OK) "$(NIXOS_HOST) rebuild complete"

dry-run: ## Dry-run build for $(NIXOS_HOST)
	@if [ -z "$(NIXOS_HOST)" ]; then \
		$(LOG_ERROR) "NIXOS_HOST is not set; activate this host's configuration first."; \
		exit 1; \
	fi
	@$(LOG_INFO) "Running dry-run build for $(NIXOS_HOST)..."
	@$(LOG_EXEC) "nix build .#nixosConfigurations.$(NIXOS_HOST).config.system.build.toplevel --dry-run"
	@nix build ".#nixosConfigurations.$(NIXOS_HOST).config.system.build.toplevel" --dry-run
	@$(LOG_OK) "Dry-run build succeeded for $(NIXOS_HOST)"

check: ## Evaluate the flake and run checks
	@$(LOG_INFO) "Evaluating flake checks..."
	@$(LOG_EXEC) "nix flake check"
	@nix flake check
	@$(LOG_OK) "Flake check passed"

fmt: ## Check Nix formatting with nixfmt-rfc-style
	@$(LOG_INFO) "Checking Nix formatting..."
	@$(LOG_EXEC) "nix run nixpkgs#nixfmt-rfc-style -- -c \$$(git ls-files '*.nix')"
	@nix run nixpkgs#nixfmt-rfc-style -- -c $$(git ls-files '*.nix')
	@$(LOG_OK) "Nix formatting check passed"

lint: ## Run Nix, Python, shell, and QML linters and tests
	@$(LOG_INFO) "Checking quickshell Nix formatting..."
	@$(LOG_EXEC) "nix run nixpkgs#nixfmt-rfc-style -- -c configuration/applications/quickshell/*.nix"
	@nix run nixpkgs#nixfmt-rfc-style -- -c configuration/applications/quickshell/*.nix
	@$(LOG_INFO) "Running statix..."
	@$(LOG_EXEC) "nix run nixpkgs#statix -- check configuration/applications/quickshell"
	@nix run nixpkgs#statix -- check configuration/applications/quickshell
	@$(LOG_INFO) "Running ruff..."
	@$(LOG_EXEC) "nix run nixpkgs#ruff -- check configuration/applications/quickshell configuration/homemanagerconfig/wallpaper_theme.py"
	@nix run nixpkgs#ruff -- check \
		configuration/applications/quickshell \
		configuration/homemanagerconfig/wallpaper_theme.py
	@$(LOG_INFO) "Running mypy..."
	@$(LOG_EXEC) "nix run nixpkgs#mypy -- --strict --ignore-missing-imports ..."
	@nix run nixpkgs#mypy -- --strict --ignore-missing-imports \
		configuration/applications/quickshell/gtk-actions.py \
		configuration/applications/quickshell/qt-menu.py \
		configuration/applications/quickshell/network_control.py \
		configuration/applications/quickshell/network_control_test.py \
		configuration/homemanagerconfig/wallpaper_theme.py
	@$(LOG_INFO) "Running Python unit tests..."
	@$(LOG_EXEC) "nix run nixpkgs#python3 -- -m unittest discover -s configuration/applications/quickshell -p '*_test.py'"
	@nix run nixpkgs#python3 -- -m unittest discover -s configuration/applications/quickshell -p '*_test.py'
	@sh_files="$$(git ls-files '*.sh')"; \
	if [ -n "$$sh_files" ]; then \
		$(LOG_INFO) "Running shellcheck..."; \
		$(LOG_EXEC) "nix run nixpkgs#shellcheck -- $$sh_files"; \
		nix run nixpkgs#shellcheck -- $$sh_files; \
	fi
	@$(LOG_INFO) "Running qmllint..."
	@$(LOG_EXEC) "qmllint configuration/applications/quickshell/config/minimal/**/*.qml"
	@qs_wrapped="$$(nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); pkgs = flake.inputs.nixpkgs.legacyPackages.$${builtins.currentSystem}; in (import ./configuration/applications/quickshell/quickshell-package.nix { inherit pkgs; inherit (flake.inputs) quickshell; }).wrapped.outPath')"; \
	qt_dec="$$(nix eval --raw nixpkgs#qt6.qtdeclarative.outPath)"; \
	qt_5c="$$(nix eval --raw nixpkgs#qt6.qt5compat.outPath)"; \
	"$$qt_dec/bin/qmllint" \
		-I "$$qt_dec/lib/qt-6/qml" \
		-I "$$qt_5c/lib/qt-6/qml" \
		-I "$$qs_wrapped/lib/qt-6/qml" \
		-I configuration/applications/quickshell/config/minimal \
		$$(find configuration/applications/quickshell/config/minimal -name 'qmldir' -printf '-i %p ') \
		$$(find configuration/applications/quickshell/config/minimal -name '*.qml' | sort)
	@$(LOG_OK) "All lint checks passed"

git: ## Stage, commit (MSG="..."), and push to origin/main
	@$(LOG_INFO) "Staging all changes..."
	@$(LOG_EXEC) "$(GIT_ADD)"
	@$(GIT_ADD)
	@$(LOG_INFO) "Committing changes..."
	@$(LOG_EXEC) "git commit -m \"$(MSG)\""
	@git commit -m "$(MSG)"
	@$(LOG_INFO) "Pushing to origin/main..."
	@$(LOG_EXEC) "git push origin main"
	@git push origin main
	@$(LOG_OK) "Git push complete"

update: ## Update all flake inputs
	@$(LOG_INFO) "Updating nix flake inputs..."
	@$(LOG_EXEC) "nix flake update"
	@nix flake update
	@$(LOG_OK) "Flake update complete"

clean: ## Wipe old profile history and collect garbage
	@$(LOG_INFO) "Wiping user profiles..."
	@$(LOG_EXEC) "nix profile wipe-history"
	@nix profile wipe-history
	@$(LOG_INFO) "Wiping system profiles older than 1 day..."
	@$(LOG_EXEC) "sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 1d"
	@sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 1d
	@$(LOG_INFO) "Collecting garbage..."
	@$(LOG_EXEC) "sudo nix-collect-garbage -d && nix-collect-garbage -d"
	@sudo nix-collect-garbage -d
	@nix-collect-garbage -d
	@$(LOG_OK) "Clean complete"

all: update git rebuild ## Update flake, commit/push (MSG="..."), and rebuild $(NIXOS_HOST)
	@$(LOG_OK) "All tasks complete"
