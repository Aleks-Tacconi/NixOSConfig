{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland/v0.56.1";
    };

    quickshell = {
      url = "github:quickshell-mirror/quickshell/7511545ee20664e3b8b8d3322c0ffe7567c56f7a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.opencode = import ./opencodeconfig/shell.nix { inherit pkgs; };

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
