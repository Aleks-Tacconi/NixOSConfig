_:

{
  imports = [ ./zsh.nix ];

  home-manager = {
    users."aleks" = {
      imports = [
        ./shellutils.nix
        ./git.nix
      ];
    };
  };
}
