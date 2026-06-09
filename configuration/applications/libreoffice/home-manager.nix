{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.packages = with pkgs; [
    caladea
    carlito
    corefonts
    onlyoffice-desktopeditors
    vista-fonts
  ];

  home.activation.onlyofficeDarkTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir="$HOME/.config/onlyoffice"
    config_file="$config_dir/DesktopEditors.conf"

    mkdir -p "$config_dir"
    touch "$config_file"

    if grep -q '^UITheme=' "$config_file"; then
      sed -i 's/^UITheme=.*/UITheme=theme-night/' "$config_file"
    else
      if ! grep -q '^\[General\]' "$config_file"; then
        printf '[General]\n' >> "$config_file"
      fi
      sed -i '/^\[General\]/a UITheme=theme-night' "$config_file"
    fi
  '';
}
