{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.sing-box;
in
{
  options = {
    services.sing-box = {
      enable = lib.mkEnableOption "sing-box universal proxy platform";

      package = lib.mkPackageOption pkgs "sing-box" { };

      subscriptionUrlFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to a file containing a subscription url.
        '';
      };

      ipFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to a file containing IPs seprated by white space or commas.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # for polkit rules
    environment.systemPackages = [ cfg.package ];
    services.dbus.packages = [ cfg.package ];
    systemd.packages = [ cfg.package ];

    systemd.services.sing-box = {
      serviceConfig = {
        User = "sing-box";
        Group = "sing-box";
        StateDirectory = "sing-box";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "sing-box";
        RuntimeDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/sing-box";
        ExecStartPre =
          let
            genconf = pkgs.writeShellApplication {
              name = "genconf";

              runtimeInputs = with pkgs; [
                nodejs_24
              ];

              text = ''
                node ${./index.ts} "$@"
              '';
            };
            script = pkgs.writeShellScript "sing-box-pre-start" ''
              ${genconf}/bin/genconf -u ${cfg.subscriptionUrlFile} -i ${cfg.ipFile} -o /run/sing-box/config.json
            '';
          in
          "${script}";
        ExecStart = [
          ""
          "${lib.getExe cfg.package} -D \${STATE_DIRECTORY} -C \${RUNTIME_DIRECTORY} run"
        ];
      };
      # After= is specified by upstream
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    users = {
      users.sing-box = {
        isSystemUser = true;
        group = "sing-box";
        home = "/var/lib/sing-box";
      };
      groups.sing-box = { };
    };

    systemd.services.sing-box-restart = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart sing-box.service";
      };
    };
    systemd.timers.sing-box-restart = {
      timerConfig = {
        OnCalendar = "*-*-* 04:00:00";
        Unit = "sing-box-restart.service";
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
