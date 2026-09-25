{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-maid.url = "git+https://codeberg.org/viperML/nix-maid";
    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon/release-2026-07-30";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    umbriel = {
      url = "github:noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lanzaboote,
      sops-nix,
      nix-maid,
      apple-silicon,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.additions ];
        }
      );
    in
    {
      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt-tree);
      packages = forAllSystems (system: import ./packages.nix { pkgs = pkgsFor.${system}; });
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
          dev = import ./shells/dev.nix {
            inherit pkgs;
            repoRoot = self.packages.${system}.repo-root;
          };
        in
        {
          default = dev;
          inherit dev;
          ci = import ./shells/ci.nix { inherit pkgs; };
        }
      );
      overlays = import ./overlays;
      nixosConfigurations = {
        mba = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            apple-silicon.nixosModules.default
            ./hosts/mba/configuration.nix
            ./modules/man-cache.nix
            {
              nixpkgs.overlays = with self.overlays; [
                additions
                modifications
              ];
            }
            nix-maid.nixosModules.default
          ];
        };
        tx = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/tx/configuration.nix
            ./modules/man-cache.nix
            {
              nixpkgs.overlays = with self.overlays; [
                additions
                modifications
              ];
            }
            lanzaboote.nixosModules.lanzaboote
            nix-maid.nixosModules.default
          ];
        };
        gk41 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/gk41/configuration.nix
            {
              nixpkgs.overlays = with self.overlays; [
                additions
                modifications
              ];
            }
            sops-nix.nixosModules.sops
          ];
        };
        ser8 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/ser8/configuration.nix
            ./modules/man-cache.nix
            sops-nix.nixosModules.sops
            {
              nixpkgs.overlays = with self.overlays; [
                additions
                modifications
              ];
            }
            lanzaboote.nixosModules.lanzaboote
          ];
        };
        ms10 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/ms10/configuration.nix
            {
              nixpkgs.overlays = with self.overlays; [
                additions
                modifications
              ];
            }
            sops-nix.nixosModules.sops
          ];
        };
        lh0 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/lh0/configuration.nix
            {
              nixpkgs.overlays = with self.overlays; [
                additions
                modifications
              ];
            }
            sops-nix.nixosModules.sops
          ];
        };
      };
    };
}
