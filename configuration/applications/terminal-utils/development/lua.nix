# Lua runtimes, packages, and editor tooling.
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
