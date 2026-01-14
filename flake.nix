{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-24.11";
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
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      lanzaboote,
      sops-nix,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";
    in
    {
      devShells."${system}".default =
        let
          pkgs = nixpkgs.legacyPackages."${system}";
          fish-config = pkgs.writers.writeFish "fish-config" ''
            # create function fish_dev_prompt
            eval (functions fish_prompt | string replace "(prompt_login)" "dev" | string replace "function fish_prompt" "function fish_dev_prompt" | string collect)

            functions -c fish_prompt fish_default_prompt

            function fish_prompt
              if test -n "$IN_NIX_SHELL"
                fish_dev_prompt
              end
              if test -z "$IN_NIX_SHELL"
                fish_default_prompt
              end
            end

            alias zed="${pkgs.zed-editor}/bin/zeditor"
          '';
          fish-wrapper = pkgs.writeShellApplication {
            name = "fish";
            text = ''
              ${pkgs.fish}/bin/fish -C "source ${fish-config}"
            '';
          };
        in
        pkgs.mkShell {
          packages = with pkgs; [
            fish-wrapper
            git
            nixd
            nixfmt-rfc-style
          ];
          shellHook =
            with pkgs;
            let
              settings = writers.writeJSON "settings.json" {
                # use fish-wrapper instead of fish — the standard shell in system-wide
                terminal = {
                  shell = {
                    program = "fish";
                  };
                };
                languages = {
                  Nix = {
                    language_servers = [ "nixd" ];
                    formatter.external = {
                      command = "nixfmt";
                    };
                  };
                };
              };
            in
            ''
              mkdir -p .zed
              ln -sf ${settings} .zed/settings.json

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
            sops-nix.nixosModules.sops
            {
              nixpkgs.overlays = with self.overlays; [
                additions
                modifications
              ];
            }
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
