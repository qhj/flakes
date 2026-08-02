{ inputs, lib }:
{
  pkgs,
  ...
}:

{
  imports = [
    inputs.noctalia.nixosModules.default
  ];
  programs.niri.enable = true;
  # place `include "/etc/niri/config.kdl"` in ~/.config/niri/config.kdl like:
  # include "/etc/niri/config.kdl"
  #
  # output "DP-1" {
  #     scale 2
  # }
  #
  environment.etc."niri/config.kdl".source = pkgs.runCommandLocal "niri-base-config.kdl" { } ''
    echo 'include "${pkgs.niri.src}/resources/default-config.kdl"' > $out
    echo >> $out

    echo 'include "extra.kdl"' >> $out
  '';
  environment.etc."niri/extra.kdl".source = pkgs.replaceVars ./extra.kdl {
    polkit-kde-agent-1 = pkgs.kdePackages.polkit-kde-agent-1;
  };
  environment.etc."noctalia/config.toml".source = pkgs.replaceVars ./noctalia-config.toml {
    sync-theme-mode =
      let
        sync-theme-mode = pkgs.writeShellApplication {
          name = "sync-theme-mode";
          runtimeInputs = with pkgs; [
            glib
            kdePackages.plasma-workspace
          ];
          text = ''
            mode="''${NOCTALIA_THEME_MODE:-}"

            if [[ -z "$mode" ]]; then
              mode="$(noctalia msg theme-mode-get)"
            fi

            case "$mode" in
              dark)
                kde_scheme="BreezeDark"
                color_scheme="prefer-dark"
                gtk_theme="Breeze-Dark"
                ;;
              light)
                kde_scheme="BreezeLight"
                color_scheme="prefer-light"
                gtk_theme="Breeze"
                ;;
              *)
                printf 'Unsupported theme mode: %s\n' "$mode" >&2
                exit 1
                ;;
            esac

            plasma-apply-colorscheme "$kde_scheme"
            gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
            gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
          '';
        };
      in
      "${sync-theme-mode}/bin/sync-theme-mode";
  };
  environment.systemPackages = with pkgs; [
    fastfetch
    ddcutil
    gpu-screen-recorder
    xwayland-satellite
    playerctl
    python3
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
  programs.noctalia = {
    enable = true;
    package =
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
        (oldAttrs: {
          nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.wrapGAppsNoGuiHook ];
          buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.gsettings-desktop-schemas ];
          dontWrapGApps = true;
          postFixup = ''
            wrapProgram "$out/bin/noctalia" \
              --prefix PATH : ${
                lib.makeBinPath [
                  pkgs.git
                ]
              } \
              "''${gappsWrapperArgs[@]}"
          '';
        });
  };
  xdg.portal.config = {
    niri."org.freedesktop.impl.portal.FileChooser" = "kde";
  };
}
