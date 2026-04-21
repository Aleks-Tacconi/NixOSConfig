{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Aleks Tacconi";
        email = "aleks.tacconi@gmail.com";
      };
      merge = {
        tool = "nvim";
      };
    };
  };
}
