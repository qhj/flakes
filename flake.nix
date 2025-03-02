{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-24.11";
  };

  outputs =
    {

      self,
      nixpkgs,
      nixpkgs-stable,
    }:
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
      overlays = import ./overlays;
      nixosConfigurations = {
        tx = nixpkgs.lib.nixosSystem {
          specialArgs = {
            pkgs-stable = import nixpkgs-stable {
              inherit system;
            };
          };
          modules = [
            ./nixos/tx/configuration.nix
            {
              nixpkgs.overlays = with self.overlays; [
                additions
              ];
            }
          ];
        };
      };
    };
}
