{
  pkgs,
  ...
}:

let
  niri-theme-environment = pkgs.writeShellApplication {
    name = "niri-theme-environment";
    runtimeInputs = with pkgs; [
      dbus
      systemd
    ];
    text = ''
      case "$1" in
        import)
          dbus-update-activation-environment --systemd \
            QT_QPA_PLATFORMTHEME=kde \
            XDG_MENU_PREFIX=plasma-
          ;;
        clear)
          systemctl --user unset-environment \
            QT_QPA_PLATFORMTHEME \
            XDG_MENU_PREFIX
          dbus-update-activation-environment \
            QT_QPA_PLATFORMTHEME= \
            XDG_MENU_PREFIX=
          ;;
      esac
    '';
  };
in
{
  imports = [
    ../noctalia
  ];
  programs.niri.enable = true;
  systemd.user.services.niri.serviceConfig = {
    ExecStartPre = "${niri-theme-environment}/bin/niri-theme-environment import";
    ExecStopPost = "${niri-theme-environment}/bin/niri-theme-environment clear";
  };
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
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    activate-linux
  ];
  hardware.i2c.enable = true;

  services.gnome.gcr-ssh-agent.enable = false;
  xdg.portal.config = {
    niri."org.freedesktop.impl.portal.FileChooser" = "kde";
  };
}
