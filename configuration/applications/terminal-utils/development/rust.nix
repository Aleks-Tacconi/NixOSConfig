# Rust toolchain, testing, and editor tooling.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cargo
    rustc
    clippy
    rustfmt
    cargo-nextest
    rust-analyzer
    bacon
  ];
}
