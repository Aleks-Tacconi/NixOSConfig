{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.packages = [ inputs.snappy-switcher.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  home.file.".config/snappy-switcher".source = config.lib.file.mkOutOfStoreSymlink ./snappy-switcher;
}
