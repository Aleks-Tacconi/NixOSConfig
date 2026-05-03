# NixOS Configuration

My personal NixOS dotfiles. 

![./assets/1.png](./assets/1.png)
![./assets/2.png](./assets/2.png)

## Features and key maps

Features include:

- Status bar
- Quickshell-powered application search and workspace overview sourced from `~/dots-hyprland`
- Notification daemon / control center with a compact Do Not Disturb switch and simplified panel layout
- Other application configurations (incl terminal configuration and tooling)
- configured tooling and dependencies for programming and my [neovim setup](https://github.com/Aleks-Tacconi/nvim-config).
- KDE connect for connecting mobile device to pc
- Different profiles for different devices
- `Tailscale` network setup
- Git configuration
> git identity is configured in `configuration/applications/terminal-utils/git.nix`
- `Jellyfin` media server
- `Syncthing` for syncing any two devices (currently disabled)
- `Hyprland` desktop configuration with WhiteSur GTK theming, WhiteSur icons, Noto Sans UI fonts, themed `hyprbars` title bars, and app-specific window rules
- Vendored `Quickshell` configuration, currently trimmed to the launcher/workspace overview, bottom dock, wallpaper selector, and a local AI sidebar
- `ImageMagick` is included in terminal utilities so the Quickshell wallpaper selector can generate wallpaper metadata and thumbnails
- `snappy-switcher` Alt-Tab window switcher themed to match the `waybar` / `swaync` palette
- `hyprlock` for lock screen, synced to the currently selected wallpaper
- Custom service for automatically syncing my obsidian notes (automatically pushed every 30 minutes if any changes)
> set up in `configuration/homemanagerconfig/services.nix`

### Status bar features

- Application launcher button
- Toggle `hyprsunset` button (night light)
- Open [nix packages](https://search.nixos.org/packages) button
- Local AI sidebar button backed by Ollama / local OpenAI-compatible models with streamed markdown/code rendering, direct replies, stable long-response rendering, and bottom-following auto-scroll
- Google calendar integration (using [nextmeeting](https://github.com/chmouel/nextmeeting))
> `nextmeeting` needs to be cloned into `~/.nextmeeting` and set up with authentication (see `nextmeeting` github)
- Media player indicator (click to pause / resume)
- Open workspaces indicator
- AI sidebar toggle
- Audio interface display (click to cycle selected audio interface)
- Volume indicator (scroll to adjust volume)
- Battery percentage
- Time (click to cycle between date / time)
- WiFi indicator (hover to show connected WiFi interface)o
- Notes button (click to open a `rofi` window with notes, type new note to add, select existing note to remove)
> You need to create a `~/.notes.md` file for this to work
- Notification indicator (click to open `swaync` panel)
- Power menu (click to open power menu)

### Key maps

> The leader key is Super (The windows button)


| Key map                                       | action |
|---------|--------|
| leader +i (where i is any integer)        | Go to workspace i       |
| leader + s                                     | Go special workspace       |
| leader + Shift + i (where i is any integer or s)        | Move selected application to workspace i |
| tap leader | Toggle Quickshell search overview |
| leader + Space                                 | Open Quickshell search   |
| leader + a | Toggle local AI sidebar |
| leader + Tab | Toggle workspace overview |
| leader + n                                 | Open notification panel |
| leader + h / j / k / l | Move selection to application (vim keybinds represent direction) |
| leader + q | Open terminal (ghostty) |
| leader + w | Open browser (zen) | 
| leader + e | Open file manager (nautilus) |
| leader + t | Reload status bar |
| leader + Shift + t | Open Quickshell wallpaper gallery |
| Alt + Tab | Switch to the next recent window |
| Alt + Shift + Tab | Switch to the previous recent window |


TODO: finish adding keybinds

## Installation and Set up

1. Clone the repository:
  
```bash
git clone git@github.com:Aleks-Tacconi/NixOSConfig.git
```

2. Navigate to the repository

```bash
cd NixOSConfig
```

3. Clone [`end-4/dots-hyprland`](https://github.com/end-4/dots-hyprland) to `~/dots-hyprland` if you want the Quickshell search/workspace overview used by this config
4. Modify any instances of user / host name to match your desired username / host name's
5. Modify `core.nix` and `pc.nix` / `laptop.nix` (or add a new profile) to select desired applications (including adding the hardware configuration for that profile)
6. (Optional) configure `nextmeeting` and create a `~/.todo.md` for all features in the status bar (for more info see the status bar section above)
7. Switch to the configuration

```bash
make laptop
```

## Additional Info

The `Makefile` contains useful commands like `clean`, `git` and `update`
