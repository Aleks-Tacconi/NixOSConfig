# Select optional utility and development groups here; remove an import to disable it.
# Language-specific dev tools live in `blueprints/` as per-project flake.nix environments.
# Only shared editor/system/infra tooling (build, cloud, data, lua, markup, nix) stays installed globally here.
{ ... }:

{
  imports = [
    ./cli.nix
    ./desktop.nix
    ./networking.nix
    ./documents.nix
    ./development/build.nix
    ./development/cloud.nix
    ./development/data.nix
    ./development/lua.nix
    ./development/markup.nix
    ./development/nix.nix
  ];
}
