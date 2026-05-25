{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

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
      cat = "bat --theme=ansi";
      cd = "z";
      open = "xdg-open";
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
      if [ -e /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ]; then
        . /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
      fi

      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec start-hyprland
      fi

      autoload -Uz compinit
      compinit

      eval "$(zoxide init zsh)"
      setopt appendhistory
      export PATH=$PATH:$HOME/.cargo/bin
      export PATH=$PATH:$HOME/.opencode/bin/
      export LD_LIBRARY_PATH="${pkgs.gcc.cc.lib}/lib:$HOME/.nix-profile/lib:$HOME/.nix-profile/lib64''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export JDTLS_HOME="$HOME/.local/share/jdtls"
      export BAT_THEME="ansi"
      export FZF_DEFAULT_OPTS='--color=fg:#e0def4,bg:#232136,hl:#ea9a97,fg+:#e0def4,bg+:#2a273f,hl+:#eb6f92,info:#9ccfd8,prompt:#c4a7e7,pointer:#f6c177,marker:#eb6f92,spinner:#f6c177,header:#908caa,border:#6e6a86,label:#9ccfd8,query:#e0def4,gutter:#232136'

      mkdir -p "$JDTLS_HOME"
    '';

    # cp -r /nix/store/*jdt-language-server*/share/java/jdtls/config_linux "$JDTLS_HOME/"
    # sudo chown -R "$USER" ~/.local/share/jdtls
    # chmod -R u+rw ~/.local/share/jdtls
  };
}
