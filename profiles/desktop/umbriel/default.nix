{ umbriel, pkgs, ... }:
{
  imports = [
    umbriel.nixosModules.default
    ../noctalia
  ];

  programs.umbriel = {
    enable = true;
    package = umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  environment.etc."umbriel/config.toml".source = ./config.toml;

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    activate-linux
  ];
}
