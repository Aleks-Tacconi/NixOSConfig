# Select optional utility and development groups here; remove an import to disable it.
{ ... }:

{
  imports = [
    ./cli.nix
    ./desktop.nix
    ./networking.nix
    ./documents.nix
    ./development/build.nix
    ./development/cloud.nix
    ./development/c-cpp.nix
    ./development/go.nix
    ./development/java.nix
    ./development/lua.nix
    ./development/rust.nix
    ./development/web.nix
    ./development/data.nix
    ./development/nix.nix
    ./development/markup.nix
    ./development/php.nix
    ./development/julia.nix
    ./development/python.nix
  ];
}
