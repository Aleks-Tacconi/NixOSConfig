{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  environment.variables.NIXOS_HOST = "laptop";

  services.ollama.enable = true;

  services = {
    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server.http_listen_port = 3100;
        common = {
          path_prefix = "/var/lib/loki";
          storage = {
            filesystem = {
              chunks_directory = "/var/lib/loki/chunks";
              rules_directory = "/var/lib/loki/rules";
            };
          };
          replication_factor = 1;
          ring = {
            instance_addr = "127.0.0.1";
            kvstore = {
              store = "inmemory";
            };
          };
        };
        schema_config = {
          configs = [
            {
              from = "2020-10-15";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };
      };
    };

    grafana = {
      enable = true;
      settings = {
        security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          enforce_domain = true;
          enable_gzip = true;
          domain = "localhost";

          # Alternatively, if you want to serve Grafana from a subpath:
          # domain = "your.domain";
          # root_url = "https://your.domain/grafana/";
          # serve_from_sub_path = true;
        };

        analytics.reporting_enabled = false;
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:3100";
            isDefault = true;
          }
        ];
      };
    };
  };

  home-manager.users."aleks".home.sessionVariables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
  };

  imports = [
    ./core.nix
    ./hardware-configuration-laptop.nix
    ../configuration/nixconfig/power_profiles.nix

    ../configuration/applications/vial/configuration.nix
  ];

  systemd.tmpfiles.rules = [ "w /sys/class/leds/tpacpi::kbd_backlight/brightness - - - - 2" ];

  environment.systemPackages = with pkgs; [
    codex
  ];
}
