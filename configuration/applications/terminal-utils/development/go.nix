# Go compiler and editor tooling.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    golangci-lint
    gopls
    go
  ];
}
