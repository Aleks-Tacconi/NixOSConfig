{
  pkgs ? import <nixpkgs> { },
  model ? "ollama/qwen3:1.7b",
  opencodeBin ? (pkgs.lib.getExe pkgs.opencode),
  configDir ? "/home/aleks/.config/opencode",
  ollamaHost ? "127.0.0.1:11434",
}:

let
  inherit (pkgs) lib;

  sandboxPath = lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.iproute2
    pkgs.ollama
    pkgs.socat
  ];

  entrypoint = pkgs.writeShellApplication {
    name = "opencode-sandbox-entrypoint";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.ollama
      pkgs.socat
    ];
    text = ''
      set -euo pipefail

      model="$1"
      shift

      model_args=(--model "$model")
      case "''${1:-}" in
        -h|--help|-v|--version|completion|acp|mcp|attach|debug|providers|auth|agent|upgrade|uninstall|serve|web|models|stats|export|import|github|session|plugin|plug|db)
          model_args=()
          ;;
      esac

      socket="$XDG_DATA_HOME/ollama.sock"
      log_file="$XDG_DATA_HOME/ollama-proxy.log"

      socat TCP-LISTEN:11434,bind=127.0.0.1,reuseaddr,fork UNIX-CONNECT:"$socket" >"$log_file" 2>&1 &
      proxy_pid=$!

      cleanup() {
        kill "$proxy_pid" >/dev/null 2>&1 || true
      }
      trap cleanup EXIT INT TERM

      attempts=0
      until ollama list >/dev/null 2>&1; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 100 ]; then
          echo "host Ollama bridge did not start; see: .opencode-sandbox-data/ollama-proxy.log" >&2
          exit 1
        fi
        sleep 0.1
      done

      if [[ "$model" == ollama/* ]]; then
        ollama_model="''${model#ollama/}"
        if ! ollama show "$ollama_model" >/dev/null 2>&1; then
          echo "Sandboxed Ollama model not found: $ollama_model" >&2
          echo "The sandbox is using host Ollama through the localhost bridge." >&2
          echo "Check that host Ollama has this model: ollama list" >&2
          exit 1
        fi
      fi

      exec /opencode-bin/opencode --pure "''${model_args[@]}" "$@"
    '';
  };

  opencode = pkgs.writeShellApplication {
    name = "opencode";
    runtimeInputs = [
      pkgs.bash
      pkgs.bubblewrap
      pkgs.coreutils
      pkgs.iproute2
      pkgs.socat
    ];
    text = ''
      set -euo pipefail

      model="''${OPENCODE_SANDBOX_MODEL:-${model}}"
      needs_bridge=1
      workspace="$(realpath "''${OPENCODE_SANDBOX_WORKSPACE:-$PWD}")"
      config_dir="''${OPENCODE_CONFIG_DIR:-${configDir}}"
      opencode_bin="$(realpath "''${OPENCODE_REAL_BIN:-${opencodeBin}}")"

      config_file="$config_dir/opencode.jsonc"
      agents_file="$config_dir/AGENTS.md"
      opencode_dir="$(dirname "$opencode_bin")"
      sandbox_data="$workspace/.opencode-sandbox-data"
      socket="$sandbox_data/ollama.sock"

      for arg in "$@"; do
        case "$arg" in
          -h|--help|-v|--version)
            needs_bridge=0
            ;;
        esac
      done

      if [ ! -x "$opencode_bin" ]; then
        echo "opencode binary not found: $opencode_bin" >&2
        exit 1
      fi

      if [ "$(basename "$opencode_bin")" != "opencode" ]; then
        echo "opencode binary must be named opencode: $opencode_bin" >&2
        exit 1
      fi

      if [ ! -f "$config_file" ]; then
        echo "opencode config not found: $config_file" >&2
        exit 1
      fi

      mkdir -p \
        "$workspace/.opencode-sandbox-cache" \
        "$workspace/.opencode-sandbox-config" \
        "$workspace/.opencode-sandbox-data" \
        "$workspace/.opencode-sandbox-home"

      host_proxy_pid=""
      if [ "$needs_bridge" = "1" ]; then
        rm -f "$socket"
        socat UNIX-LISTEN:"$socket",fork,reuseaddr TCP:${ollamaHost} >"$sandbox_data/ollama-host-proxy.log" 2>&1 &
        host_proxy_pid=$!
      fi

      cleanup() {
        if [ -n "$host_proxy_pid" ]; then
          kill "$host_proxy_pid" >/dev/null 2>&1 || true
        fi
        rm -f "$socket"
      }
      trap cleanup EXIT INT TERM

      # shellcheck disable=SC2016
      unshare --user --map-root-user --net --fork -- ${pkgs.bash}/bin/bash -c '
        set -euo pipefail

        workspace="$1"
        config_file="$2"
        agents_file="$3"
        opencode_dir="$4"
        model="$5"
        nix_ld="$6"
        nix_ld_library_path="$7"
        shift 7

        ip link set lo up

        bwrap_args=(
          --die-with-parent
          --unshare-pid
          --unshare-ipc
          --unshare-uts
          --unshare-cgroup-try
          --new-session
          --proc /proc
          --dev /dev
          --tmpfs /tmp
          --tmpfs /run
          --dir /run/current-system
          --dir /run/current-system/sw
          --dir /run/current-system/sw/share
          --ro-bind-try /run/current-system/sw/share/nix-ld /run/current-system/sw/share/nix-ld
          --ro-bind /nix /nix
          --ro-bind-try /bin /bin
          --ro-bind-try /usr /usr
          --ro-bind-try /lib /lib
          --ro-bind-try /lib64 /lib64
          --ro-bind-try /etc/ssl /etc/ssl
          --ro-bind-try /etc/protocols /etc/protocols
          --ro-bind-try /etc/services /etc/services
          --ro-bind "$opencode_dir" /opencode-bin
          --dir /opencode-config
          --ro-bind "$config_file" /opencode-config/opencode.jsonc
          --ro-bind-try "$agents_file" /opencode-config/AGENTS.md
          --bind "$workspace" /workspace
        )

        exec ${pkgs.bubblewrap}/bin/bwrap \
          "''${bwrap_args[@]}" \
          --chdir /workspace \
          --clearenv \
          --setenv HOME /workspace/.opencode-sandbox-home \
          --setenv XDG_CACHE_HOME /workspace/.opencode-sandbox-cache \
          --setenv XDG_CONFIG_HOME /workspace/.opencode-sandbox-config \
          --setenv XDG_DATA_HOME /workspace/.opencode-sandbox-data \
          --setenv OLLAMA_HOST 127.0.0.1:11434 \
          --setenv OPENCODE_CONFIG /opencode-config/opencode.jsonc \
          --setenv OPENCODE_DISABLE_DEFAULT_PLUGINS 1 \
          --setenv OPENCODE_DISABLE_EXTERNAL_SKILLS 1 \
          --setenv OPENCODE_DISABLE_CLAUDE_CODE_SKILLS 1 \
          --setenv OPENCODE_PURE 1 \
          --setenv NIX_LD "$nix_ld" \
          --setenv NIX_LD_LIBRARY_PATH "$nix_ld_library_path" \
          --setenv PATH "/opencode-bin:${sandboxPath}" \
          -- ${entrypoint}/bin/opencode-sandbox-entrypoint \
          "$model" \
          "$@"
      ' bash \
        "$workspace" \
        "$config_file" \
        "$agents_file" \
        "$opencode_dir" \
        "$model" \
        "''${NIX_LD:-}" \
        "''${NIX_LD_LIBRARY_PATH:-}" \
        "$@"
    '';
  };
in
pkgs.mkShell {
  packages = [ opencode ];

  shellHook = ''
    echo "Run isolated opencode with: opencode"
    echo "Model: ''${OPENCODE_SANDBOX_MODEL:-${model}}"
  '';
}
