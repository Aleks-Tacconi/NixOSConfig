{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  quickshellPackage = import ../applications/quickshell/quickshell-package.nix {
    inherit pkgs;
    inherit (inputs) quickshell;
  };
  greeterConfigDir = ../applications/quickshell/config/minimal;
  greeterWallpaper = ../homemanagerconfig/wallpapers/cypberpunk.jpg;
  quickshellGreeter = pkgs.writeShellScriptBin "quickshell-greeter" ''
    export QUICKSHELL_GREETER_USER="aleks"
    export QUICKSHELL_GREETER_WALLPAPER="file://${greeterWallpaper}"
    export QUICKSHELL_GREETER_CMD="${pkgs.hyprland}/bin/start-hyprland"
    exec ${quickshellPackage}/bin/qs -p ${greeterConfigDir}/greeter.qml
  '';
  greeterHyprlandConfig = pkgs.writeText "hyprland-greeter.lua" ''
    hl.config({
      misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
      },
      animations = {
        enabled = false,
      },
    })

    hl.on("hyprland.start", function()
      hl.exec_cmd("${quickshellGreeter}/bin/quickshell-greeter; ${pkgs.hyprland}/bin/hyprctl dispatch exit")
    end)
  '';
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.hyprland}/bin/start-hyprland -- --config ${greeterHyprlandConfig}";
        user = "greeter";
      };
    };
  };
}
