{
  config,
  lib,
  ...
}:

let
  cfg = config.desktop.quickshell;
  inherit (lib) mkOption types;
in
{
  options.desktop.quickshell = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the Quickshell desktop shell.";
    };

    launcher = {
      applications = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable application search in the launcher.";
      };

      files = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable file search in the launcher.";
      };

      emoji = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable emoji search in the launcher.";
      };

      clipboard = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable clipboard history in the launcher.";
      };

      fileSearch = {
        paths = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Home-relative or absolute paths available in launcher file search.";
        };

        excludes = mkOption {
          type = types.listOf types.str;
          default = [
            "node_modules"
            ".pnpm-store"
            ".yarn"
            ".next"
            ".nuxt"
            ".svelte-kit"
            ".astro"
            "dist"
            "build"
            "target"
            "out"
            "coverage"
            ".cache"
            ".npm"
            ".cargo"
            ".rustup"
            ".gradle"
            ".m2"
            ".venv"
            "venv"
            "env"
            ".env"
            "__pycache__"
            ".pytest_cache"
            ".mypy_cache"
            ".ruff_cache"
            ".tox"
            ".nox"
            ".ipynb_checkpoints"
            ".git"
            ".hg"
            ".svn"
            ".idea"
            ".vscode"
            ".direnv"
            "result"
            "result-*"
            "*.pyc"
            "*.pyo"
            "*.o"
            "*.a"
            "*.so"
            "*.class"
            "*.jar"
            "*.lock"
          ];
          description = "fd exclusion patterns used by launcher file search.";
        };
      };
    };

    notifications = {
      popupTimeout = mkOption {
        type = types.ints.positive;
        default = 4800;
        description = "Notification popup timeout in milliseconds.";
      };

      queueLimit = mkOption {
        type = types.ints.positive;
        default = 20;
        description = "Maximum number of queued notification popups.";
      };
    };

    nightLight = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to expose the night-light controls.";
      };

      temperature = mkOption {
        type = types.ints.between 1000 10000;
        default = 3500;
        description = "Night-light color temperature in Kelvin.";
      };
    };

    network.tailscale = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to expose the Tailscale connection toggle.";
    };

    appMenu = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable application menus.";
      };

      nativeMenus = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to use native application menus when available.";
      };

    };
  };

  config = {
    assertions = [
      {
        assertion =
          !cfg.enable
          || lib.any (mode: mode) (
            with cfg.launcher;
            [
              applications
              files
              emoji
              clipboard
            ]
          );
        message = "desktop.quickshell.launcher must enable at least one mode.";
      }
    ];

    home-manager.users."aleks".imports = lib.optionals cfg.enable [ ./home-manager.nix ];
  };
}
