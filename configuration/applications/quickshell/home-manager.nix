{
  pkgs,
  inputs,
  ...
}:

let
  quickshellPackage = import ./quickshell-package.nix {
    inherit pkgs;
    quickshell = inputs.quickshell;
  };
in
{
  home.packages = with pkgs; [
    quickshellPackage
    cliphist
    fuzzel
    jq
    libqalculate
    wl-clipboard
    ydotool
  ];

  home.file.".config/quickshell".source = ./config;
  home.file.".config/hypr/hyprland/scripts".source = ./hypr-scripts;
}
