{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.qhj.sunshine = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.qhj.sunshine.enable {
    # reuse this module for firewall and uinput
    services.sunshine = {
      enable = true;
      autoStart = false;
      openFirewall = true;
      capSysAdmin = false;
    };
    systemd.user.services.sunshine.enable = false;
    services.avahi.enable = false;

    systemd.services.sunshine = {
      description = "Self-hosted game stream host for Moonlight";
      wantedBy = [ "multi-user.target" ];
      wants = [
        "network-online.target"
      ];
      after = [
        "network-online.target"
      ];

      environment = {
        XDG_RUNTIME_DIR = "/run/user/1000";
      };

      serviceConfig = {
        User = "qhj";
        Group = "qhj";
        SupplementaryGroups = [
          "video"
          "uinput"
        ];

        AmbientCapabilities = [ "CAP_SYS_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_SYS_ADMIN" ];

        ExecStart = lib.escapeShellArgs [
          "${pkgs.sunshine}/bin/sunshine"
          "capture=kms"
          "origin_web_ui_allowed=pc"
          "system_tray=disabled"
        ];
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
