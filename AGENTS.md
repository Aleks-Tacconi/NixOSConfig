# AGENTS.md

Personal NixOS + Home Manager flake for two hosts: `laptop` and `pc` (`aleks`).

## Repository Map
- `flake.nix`: entrypoint (`nixosConfigurations.laptop`, `nixosConfigurations.pc`).
- `devices/core.nix`: shared system modules, base packages, and HM configuration.
- `devices/laptop.nix`, `devices/pc.nix`: host-specific imports and hardware configs.
- `configuration/nixconfig/*.nix`: core OS modules (boot, networking, users, etc.).
- `configuration/applications/<app>/configuration.nix`: system-level app modules.
- `configuration/applications/<app>/home-manager.nix`: user-level app modules.
- `configuration/applications/quickshell/config/minimal/`: Quickshell QML configuration.
- `configuration/homemanagerconfig/*.nix`: shared HM settings (themes, envvars, desktopentries).
- `home.nix`: Home Manager root module.
- `Makefile`: primary operational tasks (`rebuild`, `update`, `clean`, `git`, `all`).
- `agents/`: central configuration and shared rules for OpenCode, agy, Claude, and Cursor.

## Commands
- Rebuild current host: `make rebuild` (**warning**: runs `git add -A` first).
- Dry-run validation (laptop): `nix build .#nixosConfigurations.laptop.config.system.build.toplevel --dry-run`
- Dry-run validation (pc): `nix build .#nixosConfigurations.pc.config.system.build.toplevel --dry-run`
- Flake check: `nix flake check`
- Format check (Nix): `nix run nixpkgs#nixfmt-rfc-style -- -c $(git ls-files '*.nix')`
- Lint (Nix): `nix run nixpkgs#statix -- check .`
- Shell lint: `nix run nixpkgs#shellcheck -- $(git ls-files '*.sh')`
- Do NOT run `make git` or `make all` unless explicitly requested (auto-commits and pushes).

## Nix & Module Conventions
- Indentation: 2 spaces. Semicolon-terminated bindings.
- Keep module argument order: `{ config, pkgs, inputs, lib, ... }:`.
- Maintain system vs user boundary:
  - System modules (`configuration.nix`) enable system services and declare HM imports.
  - User modules (`home-manager.nix`) define packages, config files, and user services.
- Shared settings go in `devices/core.nix`; host-only settings in `devices/laptop.nix` or `devices/pc.nix`.
- Strings for external commands/window manager rules; booleans for Nix booleans.

## Quickshell (QML) Architecture & Conventions
- **Entry point**: `shell.qml` (`ShellRoot`) instantiates persistent services (`NetworkService`, `NotificationCenter`, `Launcher.Init`, `Bar.Init`).
- **Module Structure**: `modules/<feature>/Init.qml` is the standard module entrypoint.
- **Header Pragmas**: Use `pragma ComponentBehavior: Bound` at top of components.
- **Documentation**: Add short `/** ... */` docstring above the root component describing its role.
- **Scope vs Item**: Use `Scope` for non-visual coordinators or data controllers; `Item`/`Rectangle`/`PanelWindow` for UI.
- **Singletons & Config**:
  - `Theme`: imported via relative path (e.g. `import "../../theme"`). Always use `Theme.<token>` for colors, radii, fonts, and gaps.
  - `Config`: Nix-generated config singleton imported as `import "../.." as ShellConfig` -> `ShellConfig.Config.<feature>`.
- **Properties**: Use `root.<prop>` property qualification to avoid scope shadowing.
- **Shared UI**: Popups, section headers, spinners, and action rows live in `modules/frame/` (`PulloutPanel`, `PanelSectionHeader`, `PanelActionRow`, etc.). Avoid duplicating popup or surface styling.
- **Lists & Data**: Prefer `ScriptModel` with array values over direct raw arrays for animated list views.

## Agent Workflow Rules
- Read target files and their local patterns before editing.
- Make surgical, minimal changes. No unrelated formatting or refactoring.
- Check syntax/lint before finishing.
- Never commit or push to git without explicit user instruction.
