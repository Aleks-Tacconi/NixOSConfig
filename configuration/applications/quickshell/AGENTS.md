# Quickshell Agent Guide

Quickshell QML shell & backend daemon for NixOS (`laptop`, `pc`).
RULE: Must stay under 50 lines. Keep this file updated on any architectural change.

## Architecture
- `config/minimal/`: QML shell. Entry: `shell.qml` (`ShellRoot`).
- `config/minimal/modules/`: Subsystems (`bar`, `topleft`, `topright`, `launcher`, `dock`, `workspaceView`, `power`, `network`, `frame`).
- `home-manager.nix` & `configuration.nix`: Package, service & Config singleton generation.
- Python helpers: `network_control.py` (NM CLI/JSON), `qt-menu.py` & `gtk-actions.py` (D-Bus menu).

## Conventions & Rules
- Header: Always include `pragma ComponentBehavior: Bound` at file top.
- Size limit: Files must stay under 250 LOC; functions under 50 LOC.
- Theme: Never hardcode hex colors or arbitrary px sizes; use `Theme.<token>`.
- Scope qualification: Always use `root.<prop>` to avoid scope shadowing.
- UI/UX: Interactive elements must have `PointingHandCursor`, hover transitions, and keyboard focus/Escape handling.
- Timers: Avoid unconditional polling; gate `running` by `visible` or user interactions.
- Python: Never leave stdin unclosed on `--password-stdin`; sanitize nmcli parsing.
