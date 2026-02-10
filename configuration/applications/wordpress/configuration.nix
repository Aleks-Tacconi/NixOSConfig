{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  buddypress = pkgs.stdenvNoCC.mkDerivation {
    pname = "buddypress";
    version = "latest";
    src = pkgs.fetchzip {
      url = "https://downloads.wordpress.org/plugin/buddypress.latest-stable.zip";
      hash = "sha256-LSFH85BSTYfiSulZm9xcGZwm6ezLCn39LhcG/pWzVjw=";
    };
    installPhase = ''
      mkdir -p "$out"
      cp -R ./* "$out/"
    '';
  };

  elementor = pkgs.stdenvNoCC.mkDerivation {
    pname = "elementor";
    version = "latest";
    src = pkgs.fetchzip {
      url = "https://downloads.wordpress.org/plugin/elementor.latest-stable.zip";
      hash = "sha256-vosNTIteZ7KkOTK17EB1CEQdxLomP4n0qWifuCw0GL0=";
    };
    installPhase = ''
      mkdir -p "$out"
      cp -R ./* "$out/"
    '';
  };

  stifliFlexMcp = pkgs.stdenvNoCC.mkDerivation {
    pname = "stifli-flex-mcp";
    version = "latest";
    src = pkgs.fetchzip {
      url = "https://downloads.wordpress.org/plugin/stifli-flex-mcp.latest-stable.zip";
      hash = "sha256-40BGtYqq+FZ3EPrJK2WnVcyvFvUEg7XxlAkqie1vDvU=";
    };
    installPhase = ''
      mkdir -p "$out"
      cp -R ./* "$out/"
    '';
  };
in
{
  services.wordpress = {
    webserver = "nginx";
    sites."localhost" = {
      database.createLocally = true;
      plugins = {
        inherit buddypress elementor;
        "stifli-flex-mcp" = stifliFlexMcp;
      };
      settings = {
        WP_ENVIRONMENT_TYPE = "local";
      };
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
