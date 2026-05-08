{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/qhj/no-secrets-here.git?ref=main&shallow=1";
      flake = false;
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lanzaboote,
      sops-nix,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            neovim =
              (prev.neovim.override {
                configure = {
                  packages.paaackage = {
                    start = with prev.vimPlugins; [
                      lz-n
                    ];
                    opt = with prev.vimPlugins; [
                      snacks-nvim
                      blink-cmp
                      noice-nvim
                      which-key-nvim
                    ];
                  };
                };
              }).overrideAttrs
                (oldAttrs: {
                  buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ final.makeWrapper ];
                  postFixup = (oldAttrs.postFixup or "") + ''
                    substituteInPlace $out/bin/nvim \
                      --replace-fail "export VIMINIT=" "# export VIMINIT="
                  '';
                });
          })
        ];
      };
    in
    {
      packages."${system}" = {
        get-flake-root = pkgs.writeShellApplication {
          name = "get-flake-root";
          text = ''
            FLAKE_ROOT="''${FLAKE_ROOT:-}"
            if [[ -n "$FLAKE_ROOT" ]]; then
              echo "$FLAKE_ROOT"
              exit
            fi

            pwd="$PWD"
            while true; do
              if [[ -f "flake.nix" ]]; then
                echo "$PWD"
                exit
              fi

              if [[ $PWD == "/" ]]; then
                exit 1
              fi

              cd ..
            done

            cd "$pwd"
          '';
        };
        nvimcfg = pkgs.writeShellApplication {
          name = "nvimcfg";
          runtimeInputs = with pkgs; [
            neovim
          ];
          text = ''
            FLAKE_ROOT=$(${nixpkgs.lib.getExe self.packages.${system}.get-flake-root})
            XDG_CONFIG_HOME="$FLAKE_ROOT"/overlays/neovim nvim "$@"
          '';
        };
      };
      devShells."${system}".default = pkgs.mkShell {
        packages = with pkgs; [
          fish
          git
          nixd
          nixfmt
          lua-language-server
        ];
        shellHook = ''
          export FLAKE_ROOT=$(${nixpkgs.lib.getExe self.packages.${system}.get-flake-root})

          exec fish
        '';
      };
      overlays = import ./overlays;
      nixosConfigurations = {
        tx = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/tx/configuration.nix
            ./nixos/modules/man-cache.nix
            {
              nixpkgs.overlays = with self.overlays; [
                additions
                modifications
              ];
            }
            lanzaboote.nixosModules.lanzaboote
          ];
        };
        gk41 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/gk41/configuration.nix
            sops-nix.nixosModules.sops
          ];
        };
        ser8 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/ser8/configuration.nix
            ./nixos/modules/man-cache.nix
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
            ./nixos/hosts/ms10/configuration.nix
            sops-nix.nixosModules.sops
          ];
        };
        lh0 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/lh0/configuration.nix
            sops-nix.nixosModules.sops
          ];
        };
      };
    };
}
