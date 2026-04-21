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
  ];

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

  home.file.".vale.ini".source =
    config.lib.file.mkOutOfStoreSymlink ./configuration/homemanagerconfig/vale.ini;

}
