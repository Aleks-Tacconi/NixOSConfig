{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.username = "aleks";
  home.homeDirectory = "/home/aleks";
  home.stateVersion = "25.05";

  imports = [
    ./configuration/homemanagerconfig/envvars.nix
    ./configuration/homemanagerconfig/themes.nix
    ./configuration/homemanagerconfig/desktopentries.nix
    ./configuration/homemanagerconfig/services.nix
    ./configuration/applications/android/home-manager.nix
  ];

  programs = {
    opencode = {
      enable = true;
    };
    git = {
      enable = true;
      settings = {
        user = {
          name = "Aleks Tacconi";
          email = "aleks.tacconi@gmail.com";
        };
        merge = {
          tool = "nvim";
        };
      };
    };
  };

  home.file.".pylintrc".text = ''
    [MESSAGES CONTROL]
    disable=C0111,C0103
  '';

  home.file.".stylelint.config.js".text = ''
    module.exports = {
      extends: "stylelint-config-standard",
      plugins: ["stylelint-scss"],
      rules: {
        "at-rule-no-unknown": null,
        "scss/at-rule-no-unknown": true,
        "no-descending-specificity": null,
      },
    };
  '';

}
