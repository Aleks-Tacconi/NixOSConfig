# Lua runtimes, packages, and editor tooling.
# Kept global because Neovim configuration and plugins depend on these Lua libraries,
# luarocks, and lua-language-server/stylua across all projects.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lua51Packages.lua
    lua51Packages.jsregexp
    lua51Packages.neotest
    lua51Packages.luacheck
    lua51Packages.xml2lua
    lua-language-server
    stylua
    luajitPackages.luarocks
  ];
}
