{ umbriel, pkgs, ... }:
{
  imports = [
    umbriel.nixosModules.default
    ../noctalia
  ];

  programs.umbriel = {
    enable = true;
    package = umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
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
