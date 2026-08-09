{ pkgs, ... }:

{
  home.packages = with pkgs; [ pi-coding-agent ];

  home.sessionVariables = {
    PI_SKIP_VERSION_CHECK = "1";
  };

  home.file = {
    ".pi/agent/AGENTS.md".source = ../../../opencodeconfig/AGENTS.md;
    ".pi/agent/settings.json".source = ./settings.json;
  };
}
