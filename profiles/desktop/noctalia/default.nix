{
  noctalia,
  lib,
  pkgs,
  ...
}:
{
  imports = [ noctalia.nixosModules.default ];

  qt.enable = true;

  environment.etc."noctalia/config.toml".source = pkgs.replaceVars ./config.toml {
    noctalia-plugins-dir = "${./plugins}";
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
    ddcutil
    gpu-screen-recorder
    kdePackages.plasma-integration
    kdePackages.breeze
    kdePackages.breeze-gtk
  ];

  # remove buttons on titlebar
  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/desktop/wm/preferences".button-layout = "";
      };
    }
  ];

  programs.noctalia = {
    enable = true;
    package = noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
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
  # Firefox treats the default theme asymmetrically: a Library window opened in
  # dark mode gets an explicit "dark" override, while one opened in light mode
  # gets "none" and keeps following the system. The dark override can become
  # stale, so keep it in sync with the resolved browser theme.
  programs.firefox.autoConfig = ''
    (() => {
      const updateLibraryTheme = window => {
        if (
          window.document.documentElement.getAttribute("windowtype") !==
          "Places:Organizer"
        ) {
          return;
        }

        const theme = Services.prefs.getIntPref(
          "browser.theme.toolbar-theme",
          2
        );
        window.browsingContext.prefersColorSchemeOverride =
          theme === 0 ? "dark" : theme === 1 ? "light" : "none";
      };

      const updateOpenLibraries = () => {
        for (const window of Services.wm.getEnumerator("Places:Organizer")) {
          updateLibraryTheme(window);
        }
      };

      Services.prefs.addObserver(
        "browser.theme.toolbar-theme",
        updateOpenLibraries
      );
      Services.obs.addObserver(window => {
        window.addEventListener(
          "load",
          () => updateLibraryTheme(window),
          { once: true }
        );
      }, "domwindowopened");
    })();
  '';
}
