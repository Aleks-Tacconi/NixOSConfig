# NixOS Configuration

Personal NixOS and Home Manager configuration for my `laptop` and `pc` hosts.
The repository assumes the `aleks` user, host-specific hardware files, and my
monitor and storage layout. It is intended as a reference rather than a
drop-in configuration for another machine.

![Desktop screenshot](./assets/1.png)
![Desktop screenshot](./assets/2.png)

## Desktop

- Hyprland with host-specific monitor and workspace layouts.
- A Nix-managed Quickshell `minimal` configuration providing the top bar,
  launcher, dock, notifications, calendar, media controls, network and battery
  status, and power menu.
- Click-open top-bar panels dismiss after the pointer leaves their trigger and
  panel.
- Google Chrome as the default browser, with Helium and Firefox also installed.
- Ghostty, Nautilus, Hyprlock, SwayOSD, and Catppuccin/Papirus theming.
- KDE Connect and Jellyfin.
- An hourly systemd user service for syncing `~/SecondBrain` when it changes.
- OpenCode and selected global configuration files managed by Home Manager.

Quickshell's static configuration is deployed to
`~/.config/quickshell/minimal` from
`configuration/applications/quickshell/config/minimal`. Mutable dock pins are
stored in `~/.local/state/quickshell/minimal/dock-pins.json`.

OpenCode's `AGENTS.md`, `opencode.jsonc`, sandbox shell, and RTK plugin are
immutable Home Manager links sourced from `opencodeconfig/`. The surrounding
config and plugin directories remain writable for notifier state, dependencies,
and Herdr's generated integration.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Flake inputs, both NixOS hosts, and the OpenCode development shell |
| `devices/core.nix` | Shared system and application imports |
| `devices/laptop.nix` | Laptop hardware and host-specific settings |
| `devices/pc.nix` | PC hardware and host-specific settings |
| `configuration/nixconfig/` | Core NixOS modules |
| `configuration/applications/` | Application-specific system and Home Manager modules |
| `configuration/homemanagerconfig/` | Shared user environment, theme, and services |
| `home.nix` | Home Manager root for `aleks` |
| `opencodeconfig/` | Declarative OpenCode configuration |

## Keybindings

The leader key is Super.

| Key | Action |
| --- | --- |
| `Super+1` to `Super+9` | Switch workspace |
| `Super+Shift+1` to `Super+Shift+9` | Move the active window to a workspace |
| `Super+S` | Toggle the special workspace |
| `Super+Shift+S` | Move the active window to the special workspace |
| `Super+Space` | Open the Quickshell launcher |
| `Super+N` | Toggle the Quickshell notification center |
| `Super+Q` | Open Ghostty |
| `Super+W` | Open Google Chrome |
| `Super+E` | Open Nautilus |
| `Super+C` | Close the active window |
| `Super+V` | Toggle floating mode |
| `Super+F` | Toggle fullscreen |
| `Super+H/J/K/L` | Move focus |
| `Super+Shift+H/J/K/L` | Move the active window |
| `Alt+H/J/K/L` | Resize the active window |
| `Alt+Space` | Toggle media playback |
| `Print` | Capture a region |
| `Shift+Print` | Capture a window |

## Installation

1. Clone the repository.
2. Review the username, hardware configuration, boot device, monitor names,
   storage mounts, and host-specific settings under `devices/`.
3. Evaluate the selected host before switching:

```bash
nix build .#nixosConfigurations.laptop.config.system.build.toplevel --dry-run
```

4. Switch to the selected host:

```bash
sudo nixos-rebuild switch --flake .#laptop
```

Use `#pc` for the desktop host.

## Commands

| Command | Behavior |
| --- | --- |
| `nix flake check` | Evaluate the flake |
| `make laptop` | Mount the configured laptop boot partition if needed, stage all Git changes, and rebuild `laptop` |
| `make pc` | Stage all Git changes and rebuild `pc` |
| `make update` | Update all flake inputs |
| `make clean` | Remove old user/system profile history and run system and user garbage collection |
| `make git MSG="message"` | Stage, commit, and push to `origin/main` |
| `make all MSG="message"` | Update, commit, push, and rebuild the laptop |
| `nix develop .#opencode` | Enter the isolated OpenCode/Ollama development shell |

`make git` and `make all` push changes. `make clean` removes old generations.
Review their recipes before running them.

Utility targets in `RootMakefile` are invoked with
`make -f RootMakefile <target>`.
