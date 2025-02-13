{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      tx = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/tx/configuration.nix
        ];
      };
    };
  };
}
