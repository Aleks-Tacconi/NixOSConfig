{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  hyprlandPkg = pkgs.hyprland;
in
{
  programs.zsh = {
    enable = true;

    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ".." = "cd ..";
      v = "nvim";
      ls = "eza --group-directories-first --git";
      ll = "ls -lah";
      cat = "bat";
      cd = "z";
      open = "xdg-open";
      nix-shell = ''nix-shell --run "$SHELL"'';
    };

    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "fzf"
      ];
    };

    histFile = "$HOME/.histfile";
    histSize = 1000;

    interactiveShellInit = ''
      # Use the configured shell when entering a development environment.
      nix() {
        if [[ $1 == "develop" ]]; then
          shift
          command nix develop "$@" -c "$SHELL"
        else
          command nix "$@"
        fi
      }

      # Mark Nix environments after the prompt theme has loaded.
      nix_shell_prompt() {
        if [[ -n "$IN_NIX_SHELL" && "$PROMPT" != '%F{#89dceb}%f '* ]]; then
          local prompt_body="''${PROMPT#*\) }"
          PROMPT='%F{#89dceb}%f  '"$prompt_body"
        fi
      }
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd nix_shell_prompt

      if [ -e /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ]; then
        . /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
      fi

      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec ${pkgs.coreutils}/bin/env -u LD_LIBRARY_PATH ${pkgs.util-linux}/bin/setpriv --inh-caps=-all --ambient-caps=-all ${hyprlandPkg}/bin/start-hyprland
      fi

      eval "$(zoxide init zsh)"
      setopt appendhistory
      export PATH=$PATH:$HOME/.cargo/bin
      export JDTLS_HOME="$HOME/.local/share/jdtls"
      export BAT_THEME="ansi"
      export FZF_DEFAULT_OPTS='--color=fg:#e0def4,hl:#ea9a97,fg+:#e0def4,bg+:#2a273f,hl+:#eb6f92,info:#9ccfd8,prompt:#c4a7e7,pointer:#f6c177,marker:#eb6f92,spinner:#f6c177,header:#908caa,border:#6e6a86,label:#9ccfd8,query:#e0def4,gutter:#232136'

      mkdir -p "$JDTLS_HOME"
    '';

    # cp -r /nix/store/*jdt-language-server*/share/java/jdtls/config_linux "$JDTLS_HOME/"
    # sudo chown -R "$USER" ~/.local/share/jdtls
    # chmod -R u+rw ~/.local/share/jdtls
  };
}
