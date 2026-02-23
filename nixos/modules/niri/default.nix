{ inputs }:
{
  pkgs,
  ...
}:

{
  programs.niri.enable = true;
  environment.etc."niri/config.kdl".source =
    pkgs.runCommand "niri-base-config.kdl" { preferLocalBuild = true; }
      ''
        echo 'include "${pkgs.niri.src}/resources/default-config.kdl"' > $out
        echo >> $out

        echo 'include "extra.kdl"' >> $out
      '';
  environment.etc."niri/extra.kdl".source = pkgs.replaceVars ./extra.kdl {
    polkit-kde-agent-1 = pkgs.kdePackages.polkit-kde-agent-1;
  };
  environment.systemPackages = with pkgs; [
    (
      let
        noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      in
      # add gsettings-desktop-schemas to XDG_DATA_DIRS
      noctalia.overrideAttrs (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
          pkgs.wrapGAppsHook3
        ];
        # https://nixos.org/manual/nixpkgs/stable/#ssec-gnome-common-issues-double-wrapped
        dontWrapGApps = true;
        preFixup = (oldAttrs.preFixup or [ ]) + ''
          qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
        '';
      })
    )
    (writeShellApplication {
      name = "auto-dark";
      runtimeInputs = [ glib ];
      text = ''
        gsettings set org.gnome.desktop.interface color-scheme "$([ "$1" = true ] && printf 'prefer-dark' || printf 'prefer-light')"

        # needed for some apps like Remmina
        gsettings set org.gnome.desktop.interface gtk-theme "$([ "$1" == true ] && printf 'Adwaita-dark' || printf 'Adwaita')"
      '';
    })
    ddcutil
    gpu-screen-recorder
    gnome-themes-extra # Adwaita theme
    glib # gsettings
  ];
  hardware.i2c.enable = true;

  # remove buttons on titlebar
  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/desktop/wm/preferences".button-layout = "";
      };
    }
  ];
  services.gnome.gcr-ssh-agent.enable = false;
}
