{ inputs, pkgs, ... }:
{
  imports = [
    inputs.umbriel.nixosModules.default
    ../noctalia
  ];

  programs.umbriel = {
    enable = true;
    package =
      inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
        (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [ ./default-keybinds.patch ];
        });
  };

  environment.etc."umbriel/config.toml".source = ./config.toml;

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    ghostty
    activate-linux
  ];
}
