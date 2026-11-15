{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:quickshell-mirror/quickshell/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/snapshot.tar.gz";
    };

    rex-rune = {
      url = "github:Aleks-Tacconi/rex-rune";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    {
      nixosConfigurations."pc" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./devices/pc.nix
        ];
      };

      nixosConfigurations."laptop" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./devices/laptop.nix
        ];
      };
    };
}
