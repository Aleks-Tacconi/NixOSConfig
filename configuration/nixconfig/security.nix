{ config, pkgs, inputs, lib, ... }:

{
  security.sudo.extraRules = [{
    users = [ "aleks" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
