# NixOS Configuration

Personal NixOS and Home Manager configuration for the `laptop` and `pc` hosts.
It assumes the `aleks` user and host-specific hardware, monitor, and storage
layouts, so it is a reference rather than a drop-in configuration.

![Desktop screenshot](./assets/1.png)

## Desktop

- Hyprland with host-specific monitor and workspace layouts.
- Nix-managed Quickshell `minimal`: top bar, launcher, dock, notifications,
  calendar, media controls, network/battery status, and power menu. Click-open
  top-bar panels close after the pointer leaves their trigger and panel.
- Google Chrome by default, plus Helium and Firefox.
- Ghostty, Nautilus, Hyprlock, SwayOSD, Catppuccin/Papirus theming, KDE Connect,
  and Jellyfin.
- Preservation-oriented Google Drive sync on both hosts and Syncthing for
  `~/ObsidianVault` between them.
- OpenCode and selected global configuration managed by Home Manager.

Quickshell's static configuration is deployed from
`configuration/applications/quickshell/config/minimal` to
`~/.config/quickshell/minimal`; mutable dock pins live at
`~/.local/state/quickshell/minimal/dock-pins.json`.

OpenCode's `AGENTS.md`, `opencode.jsonc`, sandbox shell, and RTK plugin are
immutable Home Manager links from `opencodeconfig/`. The surrounding config and
plugin directories stay writable for notifier state, dependencies, and Herdr's
generated integration.

## Google Drive

Both hosts keep a complete offline copy at `~/Google Drive`. Each independently
runs `rclone bisync` directly against `gdrive:` every five minutes, using the
same package, commands, state layout, and systemd units. User lingering keeps
timers active after logout.

### Setup

Set up each host independently, in either order, as `aleks`:

```bash
rclone config
rclone lsd gdrive:
gdrive-sync
gdrive-sync status
```

In `rclone config`, create a remote named exactly `gdrive`, grant full Drive
access, and complete browser OAuth. A personal Google API client ID is
recommended for regular sync but is optional. Credentials remain in
`~/.config/rclone/rclone.conf`; never commit that file or its OAuth tokens.

Initialization refuses a non-empty `~/Google Drive` and uses Drive as the
authoritative first copy. Scheduled jobs wait for the first successful manual
`gdrive-sync`, which initializes the folder when needed and enables automatic
five-minute sync.

Monitor the timer and service with:

```bash
systemctl --user status google-drive-sync.timer
journalctl --user -u google-drive-sync.service -f
```

### Behavior

- Create, edit, rename, move, or delete ordinary files normally in
  `~/Google Drive`.
- A move is copied to the new path, then deleted from the old path. It propagates
  normally while the old path is archived.
- Deletions propagate but are recoverable: replaced/deleted local versions go
  to `~/.local/state/gdrive-sync/backups/`, and Drive versions go to
  `gdrive:.gdrive-sync/history/`. UUID-based run directories prevent history
  collisions, and Google Drive trash is forced on.
- If both hosts edit the same path before syncing, the newer modification time
  wins and the losing version gets a numbered `conflict` suffix.
- A run aborts before applying more than 1000 deletions. Reports are stored in
  `~/.local/state/gdrive-sync/reports/`; failures trigger a desktop notification.
- Daily cleanup retains local backups and Drive history for 30 days and reports
  for 14 days. It permanently removes expired reserved Drive history to release
  storage, never active files. Both hosts use the same cleanup service with a
  random delay to reduce simultaneous remote cleanup.
- Google Docs, Sheets, Slides, and Drawings appear in their normal hierarchy as
  `.url` files that open the browser document. They require internet access and
  are edited in Drive; no separate offline export folder exists.
- Any file or directory name beginning with uppercase `PRIVATE` is excluded at
  any depth and never uploads or downloads. The rule is case-sensitive, for
  example `PRIVATE-notes.txt` and `work/PRIVATE-project/`.
- `.gdrive-sync` is excluded so archived versions cannot re-enter the live tree.

### Recovery and Security

Bisync never resyncs automatically. If rclone requires state recovery, first
preserve unsynchronized local work outside `~/Google Drive`, then run the
Drive-authoritative recovery:

```bash
gdrive-sync resync
```

The health check requires rclone's Google Drive backend and rejects disabled TLS
certificate verification. Certificate-validated HTTPS encrypts transfers in
transit, but Google can read the data. Google Drive provides no distributed
rclone lock, so simultaneous runs can overlap; numbered conflicts and UUID-based
histories aid recovery but do not guarantee zero data loss.

## Syncthing

Syncthing runs as `aleks` on both hosts and syncs `~/ObsidianVault`. Its web UI
is local-only at <http://127.0.0.1:8384>; firewall ports are open for device
discovery and transfers, not the web UI.

Start with the existing vault on one host only and let Syncthing populate the
other:

1. Rebuild both hosts and open <http://127.0.0.1:8384> on each.
2. On one host, select **Actions > Show ID** and copy its device ID.
3. On the other, select **Add Remote Device**, enter the ID and a recognizable
   name, then save.
4. Accept the pending device request on the first host.
5. On the host with the vault, select **Add Folder**, set the path to
   `/home/aleks/ObsidianVault`, select the other device under **Sharing**, and
   save.
6. Accept the folder request on the other host and use the same path.
7. When both report **Up to Date**, open the directory as an Obsidian vault on
   each host.

Check service status and logs with:

```bash
systemctl status syncthing.service
journalctl -u syncthing.service -f
```

## Repository Layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Flake inputs, both NixOS hosts, and the OpenCode development shell |
| `devices/core.nix` | Shared system and application imports |
| `devices/laptop.nix` | Laptop hardware and host-specific settings |
| `devices/pc.nix` | PC hardware and host-specific settings |
| `configuration/nixconfig/` | Core NixOS modules |
| `configuration/applications/` | Application-specific system and Home Manager modules |
| `configuration/homemanagerconfig/` | Shared user environment, theme, and desktop configuration |
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
   storage mounts, and host-specific settings in `devices/`.
3. Evaluate the host: `nix build .#nixosConfigurations.laptop.config.system.build.toplevel --dry-run`.
4. Switch to it: `sudo nixos-rebuild switch --flake .#laptop`.

Use `#pc` instead for the desktop host.

## Commands

| Command | Behavior |
| --- | --- |
| `nix flake check` | Evaluate the flake |
| `make rebuild` | Rebuild the system |
| `make update` | Update all flake inputs |
| `make clean` | Remove old user/system profile history and run system and user garbage collection |
| `make git MSG="message"` | Stage, commit, and push to `origin/main` |
| `make all MSG="message"` | Update, commit, push, and rebuild the laptop |
| `nix develop .#opencode` | Enter the isolated OpenCode/Ollama development shell |

`make git` and `make all` push changes; `make clean` removes old generations.
Review their recipes before use. Run `RootMakefile` utilities with
`make -f RootMakefile <target>`.
