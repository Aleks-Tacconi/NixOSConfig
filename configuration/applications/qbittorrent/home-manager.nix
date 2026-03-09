{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  draculaQbittorrent = pkgs.fetchFromGitHub {
    owner = "dracula";
    repo = "qbittorrent";
    rev = "b0a638dbac23c275a0e098d08b0ad8af3de2764b";
    hash = "sha256-FirLP1xVIC0JnPZYuCl1pqdBboLkXINN5la7oFMUovA=";
  };
in
{
  home.packages = with pkgs; [ qbittorrent ];

  home.file.".config/qBittorrent/themes/dracula.qbtheme".source =
    "${draculaQbittorrent}/dracula.qbtheme";
}
