{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  herdrPackage = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  pluginPath = "${config.home.homeDirectory}/NixOSConfig/configuration/applications/herdr/worktree-bootstrap";
in
{
  home.file.".config/herdr/config.toml".text = ''
    [theme]
    name = "catppuccin"

    [theme.custom]
    accent = "#f38ba8"
    panel_bg = "reset"
    surface0 = "#313244"

    [ui]
    hide_tab_bar_when_single_tab = true
    pane_borders = true
    pane_gaps = false

    [keys]
    prefix = "ctrl+s"

    settings = ""
    workspace_picker = "prefix+s"
    reload_config = "prefix+r"
    new_worktree = "prefix+w"
    open_worktree = "prefix+o"
    remove_worktree = "prefix+d"
    previous_workspace = "prefix+left"
    next_workspace = "prefix+right"
    open_notification_target = ""

    navigate_workspace_up = "k"
    navigate_workspace_down = "j"
    navigate_pane_left = "h"
    navigate_pane_right = "l"

    new_tab = "prefix+c"
    switch_tab = "prefix+1..9"
    split_vertical = "prefix+percent"
    split_horizontal = "prefix+double_quote"

    focus_pane_left = "prefix+h"
    focus_pane_down = "prefix+j"
    focus_pane_up = "prefix+k"
    focus_pane_right = "prefix+l"

    [[keys.command]]
    key = "prefix+i"
    type = "plugin_action"
    command = "aleks.worktree-bootstrap.bootstrap"
    description = "bootstrap editor and agent tabs"
  '';

  home.activation.linkHerdrWorktreeBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    case "$(${herdrPackage}/bin/herdr status server 2>/dev/null)" in
      *"status: running"*)
        $DRY_RUN_CMD ${herdrPackage}/bin/herdr plugin link "${pluginPath}" >/dev/null
        $DRY_RUN_CMD ${herdrPackage}/bin/herdr server reload-config >/dev/null
        ;;
    esac
  '';
}
