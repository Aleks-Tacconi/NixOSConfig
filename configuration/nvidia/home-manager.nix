{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
  };
}
