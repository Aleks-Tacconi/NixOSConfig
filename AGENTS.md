# AGENTS.md

## Purpose
- This repository is a personal NixOS + Home Manager flake for two hosts: `laptop` and `pc`.
- Use this file as the default operating guide for coding agents working in this repo.
- Prefer minimal, targeted changes that preserve existing module boundaries.

## Repository Map
- `flake.nix`: flake entrypoint defining `nixosConfigurations.laptop` and `nixosConfigurations.pc`.
- `devices/core.nix`: shared system modules and base packages for all hosts.
- `devices/laptop.nix`, `devices/pc.nix`: host-specific imports and settings.
- `configuration/nixconfig/*.nix`: core OS configuration modules (boot, networking, users, etc).
- `configuration/applications/*/configuration.nix`: system-level app modules.
- `configuration/applications/*/home-manager.nix`: user-level app config modules.
- `configuration/homemanagerconfig/*.nix`: shared HM settings (themes, env vars, services).
- `home.nix`: Home Manager root module for user `aleks`.
- `Makefile`: primary operational commands for rebuild/update/cleanup.
- `RootMakefile`: utility tasks (Jellyfin reset, disk inspection, jdtls config copy).

## Cursor / Copilot Rule Files
- Checked `.cursor/rules/`: not present.
- Checked `.cursorrules`: not present.
- Checked `.github/copilot-instructions.md`: not present.
- No external editor-agent rule files are currently defined.

## Build / Rebuild Commands
- Rebuild the current host (preferred local shortcut): `make rebuild`
- Direct laptop switch: `sudo nixos-rebuild switch --flake ./#laptop`
- Direct PC switch: `sudo nixos-rebuild switch --flake ./#pc`
- Evaluate all flake outputs/checks: `nix flake check`
- Dry-run build for laptop closure: `nix build .#nixosConfigurations.laptop.config.system.build.toplevel --dry-run`
- Dry-run build for pc closure: `nix build .#nixosConfigurations.pc.config.system.build.toplevel --dry-run`
- Update inputs: `make update` or `nix flake update`
- Cleanup old generations/artifacts: `make clean`

## Important Command Side Effects
- `make rebuild` runs `git add -A` before rebuilding the host selected by `NIXOS_HOST`.
- `make git` stages, commits, and pushes to `origin/main`.
- `make all` runs `update`, `git`, and `rebuild` (includes push).
- Do not run `make git` or `make all` unless the user explicitly requests commit/push behavior.

## Lint / Format Commands
- Nix format check (all Nix files):
  `nix run nixpkgs#nixfmt-rfc-style -- -c $(git ls-files '*.nix')`
- Nix format write (all Nix files):
  `nix run nixpkgs#nixfmt-rfc-style -- $(git ls-files '*.nix')`
- Nix lint suggestions: `nix run nixpkgs#statix -- check .`
- Nix dead code scan: `nix run nixpkgs#deadnix -- .`
- Shell lint (when shell scripts are present):
  `nix run nixpkgs#shellcheck -- $(git ls-files '*.sh')`
- Shell syntax check (single file): `bash -n path/to/script.sh`
- Python checks apply only when Python files are present.

## Test Commands (and "Single Test" Guidance)
- There is no dedicated unit/integration test suite in this repo today.
- `nix flake check` is the broadest project-level validation command.
- Closest equivalent to a single test is targeted host evaluation/build.
- Single host validation (laptop):
  `nix build .#nixosConfigurations.laptop.config.system.build.toplevel --dry-run`
- Single host validation (pc):
  `nix build .#nixosConfigurations.pc.config.system.build.toplevel --dry-run`
- Single option evaluation example:
  `nix eval .#nixosConfigurations.laptop.config.programs.wireshark.enable`

## Nix Code Style
- Use 2-space indentation consistently.
- End all Nix assignments with semicolons.
- Prefer trailing commas only where required by syntax; current style is mostly semicolon-separated attrs.
- Keep module argument sets in existing order when present:
  `{ config, pkgs, inputs, lib, ... }:` or close variant.
- Preserve the split between system modules and Home Manager modules.
- Prefer one package per line in `environment.systemPackages` / `home.packages` lists.
- Keep grouped comments short and purposeful (examples: `# nvim stuff`, `# Misc utilities`).
- Follow existing pattern for app modules:
  - `configuration.nix` wires system settings and HM import.
  - `home-manager.nix` defines user-level packages/files/services.
- Use `with pkgs; [ ... ]` where surrounding code already uses it.
- Avoid broad refactors of unrelated package lists.

## Imports and Module Organization
- Add shared settings in `devices/core.nix` only if both hosts should inherit them.
- Add host-specific settings in `devices/laptop.nix` or `devices/pc.nix`.
- For a new app module, mirror existing layout:
  `configuration/applications/<app>/configuration.nix`
  `configuration/applications/<app>/home-manager.nix`
- Wire new modules by adding import entries in `devices/core.nix` (or host file when host-specific).
- Keep import lists readable and stable; avoid unnecessary reordering.

## Naming Conventions
- Directory names are lowercase (examples: `chrome`, `hyprlock`, `quickshell`).
- Nix module files are usually descriptive snake_case or conventional names:
  `configuration.nix`, `home-manager.nix`, `display_manager.nix`.
- Keep host names exactly as flake outputs define them: `laptop`, `pc`.
- Preserve existing user naming (`users.users.aleks`, `home.username = "aleks"`).

## Types and Values
- Use booleans for Nix booleans (`true` / `false`), not quoted strings.
- Use strings only where upstream config expects string values (common in Hyprland settings).
- Use explicit lists for multi-value settings (`extraGroups`, package lists, port ranges).
- Use attribute sets for structured config blocks (`networking`, `services`, `programs`).

## Error Handling and Safety
- In shell snippets embedded in Nix, guard risky operations (`cd ... || exit 1`).
- Fail with non-zero exit codes when script operations cannot proceed.
- Write human-readable errors to stderr in scripts (`>&2`).
- Quote variable expansions in shell scripts by default.
- Check file writability before mutating user files when practical.
- Avoid destructive system actions unless clearly requested.

## Shell Script Conventions
- Keep shell scripts small and focused; this repo uses utility-style scripts.
- Prefer readable pipelines and explicit temporary variables.
- Use `mapfile` for array capture where multi-line command output is expected.
- Keep command invocations portable for NixOS user environments.

## Python Conventions
- Keep Python scripts minimal, single-purpose, and dependency-light.
- Use `snake_case` for functions and variables.
- Add type hints where they improve clarity (`def main() -> None`).
- Prefer straightforward stdlib usage unless regex/unicode handling needs external libs.

## QML / JSON / CSS Conventions
- Preserve existing formatting style within each file rather than reformatting wholesale.
- Keep keys grouped logically in JSON and JSONC configs.
- Keep shared Quickshell popup behavior in `modules/frame` rather than duplicating it.
- Keep CSS selectors grouped by component/area.
- Avoid mass reindent changes unless requested.

## Agent Workflow Checklist
- Identify target host impact first (`laptop`, `pc`, or both).
- Change the smallest relevant module(s) only.
- Run targeted validation (at minimum `nix flake check` or host dry-run build).
- If touching scripts, run syntax/lint checks for modified scripts.
- Report warnings from validation commands (for example xorg deprecation warnings) without hiding them.

## Commit Hygiene for Agents
- Do not commit or push unless explicitly asked by the user.
- If asked to commit, avoid bundling unrelated changes.
- Never rewrite history unless explicitly requested.
