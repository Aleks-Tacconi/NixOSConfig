{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  gccLib = pkgs.stdenv.cc.cc.lib;
  glibc = pkgs.glibc;
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
      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland
      fi

      autoload -Uz compinit
      compinit

      eval "$(zoxide init zsh)"
      setopt appendhistory
      export PATH=$PATH:$HOME/.cargo/bin
      export LD_LIBRARY_PATH="$HOME/.nix-profile/lib:$HOME/.nix-profile/lib64:${gccLib}/lib:$LD_LIBRARY_PATH:${glibc}/lib"
      export JDTLS_HOME="$HOME/.local/share/jdtls"
      mkdir -p "$JDTLS_HOME"
    '';

    # cp -r /nix/store/*jdt-language-server*/share/java/jdtls/config_linux "$JDTLS_HOME/"
    # sudo chown -R "$USER" ~/.local/share/jdtls
    # chmod -R u+rw ~/.local/share/jdtls
  };
}
