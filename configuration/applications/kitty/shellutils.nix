{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  programs.java = {
    enable = true;
    package = pkgs.javaPackages.compiler.openjdk21;
  };

  home.packages = with pkgs; [
    # nvim stuff
    vscode-extensions.ms-vscode.cpptools-extension-pack
    vscode-extensions.ms-vscode.cpptools

    gdb
    lazygit

    vscode-extensions.vscjava.vscode-java-debug
    vscode-extensions.vscjava.vscode-java-test

    postgres-language-server
    # postgres-lsp
    sqlfluff
    pgformatter

    clang-tools
    valgrind

    golangci-lint
    gopls
    go
    libxml2
    lemminx

    lsof

    lua51Packages.lua
    lua51Packages.jsregexp
    lua51Packages.neotest
    lua51Packages.luacheck
    lua51Packages.xml2lua

    lua-language-server
    stylua
    vscode-langservers-extracted
    jdt-language-server
    nodePackages.prettier
    docker-compose-language-service

    dockerfile-language-server
    docker-ls
    hadolint
    htmlhint
    typescript-language-server
    typescript
    eslint
    eslint_d
    marksman
    markdownlint-cli
    nil
    nixfmt-rfc-style
    pyright
    lombok
    checkstyle
    google-java-format

    # Core CLI utilities
    zip
    eza
    tree
    xdg-utils
    marksman
    php84Packages.composer
    php
    julia_111-bin
    tree-sitter
    ripgrep
    fd
    fzf
    zoxide
    bat
    jq
    cpplint
    maven
    icu

    # Desktop / Wayland tools
    hyprshot
    wl-clipboard
    brightnessctl
    desktop-file-utils
    libnotify

    # Networking / security
    openvpn
    sshfs
    nmap
    dig
    magic-wormhole

    # Build tools / compilers / libs
    gnumake
    gcc
    libgcc
    libGL
    glibc
    glib
    rubyPackages.glib2
    stdenv.cc.cc.lib
    zlib

    # Python ecosystem
    (python313.withPackages (
      ps: with ps; [
        debugpy
        numpy
        regex
        tkinter
        stdenv
        pip
        pynvim
        pylatexenc
        virtualenv
      ]
    ))

    black
    isort
    poetry
    pylint

    # Other programming tools
    cargo
    rustc
    nix-search-cli
    uv
    luajitPackages.luarocks
    stylelint
    stylelint-lsp
    mprocs
    postgresql
    swi-prolog

    # Misc utilities
    unzip
    wget
    ffmpeg
    ripmime
    gcalcli
    tracy
    kdePackages.wayland-protocols
    upower
    wlr-protocols
    sqlite
    xwayland-run
    playerctl
    ncdu
    xorg.xrandr
    libxcvt
    libdrm
    pulseaudioFull
    curl

    # Controller tooling
    bluez
    usbutils
    pciutils
    linuxConsoleTools

    # electron build
    dpkg
    fakeroot
    rpm
  ];
}
