{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
    in
    {
      devShells."${system}".default =
        let
          pkgs = nixpkgs.legacyPackages."${system}";
        in
        pkgs.mkShell {
          packages = with pkgs; [
            fish
            nixd
            nixfmt-rfc-style
          ];
          shellHook = ''
            exec fish
          '';
        };
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
