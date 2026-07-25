{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  quickshellPackage = import ./quickshell-package.nix {
    inherit pkgs;
    inherit (inputs) quickshell;
  };
in
{
  home.packages = with pkgs; [
    quickshellPackage
    cliphist
    wl-clipboard
  ];

  xdg.configFile."quickshell/minimal".source = ./config/minimal;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Environment = "QUICKSHELL_CONFIG_GENERATION=${./config/minimal}";
      ExecStartPre = "-${quickshellPackage}/bin/qs kill --any-display -c minimal";
      ExecStart = "${quickshellPackage}/bin/qs -c minimal";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.activation.ensureMinimalQuickshellState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p \
      "${config.xdg.stateHome}/quickshell/minimal"
  '';
}
