{ pkgs, ... }:

{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;
  };

  xdg.configFile = {
    "opencode/AGENTS.md".source = ../../../opencodeconfig/AGENTS.md;
    "opencode/opencode.jsonc".source = ../../../opencodeconfig/opencode.jsonc;
    "opencode/shell.nix".source = ../../../opencodeconfig/shell.nix;
    "opencode/plugins/rtk.ts".source = ../../../opencodeconfig/plugins/rtk.ts;
  };
}
