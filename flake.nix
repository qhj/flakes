{
  description = "A very basic flake";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
      "https://umbriel.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw="
    ];
  };

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
      url = "github:noctalia-dev/noctalia/cachix";
    };
    nix-maid.url = "git+https://codeberg.org/viperML/nix-maid";
    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
    };
    umbriel = {
      url = "github:noctalia-dev/umbriel/cachix";
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
      noctalia,
      umbriel,
      ...
    }:
    let
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
      systemOverlays = with self.overlays; [
        additions
        modifications
      ];
      overlayModule = {
        nixpkgs.overlays = systemOverlays;
      };
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
          specialArgs = { inherit noctalia umbriel; };
          modules = [
            apple-silicon.nixosModules.default
            (
              { lib, ... }:
              {
                hardware.asahi.pkgs = lib.mkForce (
                  import apple-silicon.inputs.nixpkgs {
                    localSystem.system = "aarch64-linux";
                    crossSystem.system = "aarch64-linux";
                    overlays = [ apple-silicon.overlays.default ];
                  }
                );
              }
            )
            ./hosts/mba
            overlayModule
            sops-nix.nixosModules.sops
            nix-maid.nixosModules.default
          ];
        };
        tx = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit noctalia;
            overlays = systemOverlays;
            maidModule = nix-maid.nixosModules.default;
          };
          modules = [
            ./hosts/tx
            overlayModule
            lanzaboote.nixosModules.lanzaboote
            nix-maid.nixosModules.default
          ];
        };
        gk41 = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/gk41
            overlayModule
            sops-nix.nixosModules.sops
            nix-maid.nixosModules.default
          ];
        };
        ser8 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit noctalia; };
          modules = [
            ./hosts/ser8
            sops-nix.nixosModules.sops
            overlayModule
            lanzaboote.nixosModules.lanzaboote
            nix-maid.nixosModules.default
          ];
        };
        ms10 = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/ms10
            overlayModule
            sops-nix.nixosModules.sops
            nix-maid.nixosModules.default
          ];
        };
        lh0 = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/lh0
            overlayModule
            sops-nix.nixosModules.sops
            nix-maid.nixosModules.default
          ];
        };
      };
    };
}
