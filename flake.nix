{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    inherit (self) outputs;
  in {
    overlays.default =
      final: prev:
      prev.lib.packagesFromDirectoryRecursive {
        inherit (prev) callPackage;
        directory = ./pkgs;
      };
    nixosConfigurations = {
      tx = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/tx/configuration.nix
	  { nixpkgs.overlays = [ self.overlays.default ]; }
        ];
      };
    };
  };
}
