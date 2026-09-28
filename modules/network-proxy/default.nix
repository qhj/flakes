{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.qhj.network-proxy = {
    enable = lib.mkEnableOption "";
    mode = lib.mkOption {
      type = lib.types.enum [
        "router"
        "local"
      ];
      default = "router";
      description = "Whether to proxy forwarded router traffic or only traffic from this host.";
    };
    inputFile = lib.mkOption {
      type = lib.types.externalPath;
      description = "Absolute path to the runtime JSON input file for sing-box configuration generation.";
    };
  };

  config = lib.mkIf config.qhj.network-proxy.enable (
    let
      cfg = config.qhj.network-proxy;
      isRouter = cfg.mode == "router";
      singBoxUser = config.systemd.services.sing-box.serviceConfig.User;
      netbirdClients = lib.attrValues config.services.netbird.clients;
      hasNetbird = netbirdClients != [ ];
      netbirdUsers = lib.unique (
        map (client: client.user.name) (lib.filter (client: client.hardened) netbirdClients)
      );
      mark = "7";
      netbirdMark = "0x1bd00";
    in
    {
      services.sing-box.enable = true;
      systemd.services.sing-box = {
        preStart = "${pkgs.nodejs_24}/bin/node ${./index.ts} -i ${lib.escapeShellArg cfg.inputFile} -o /etc/sing-box/config.json --mode ${cfg.mode}";
        serviceConfig = {
          ConfigurationDirectoryMode = "0700";
        };
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
      systemd.services.dnsmasq-china-list-update = lib.mkIf isRouter {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.nodejs_24}/bin/node ${./update-dnsmasq-china-list.ts}";
          ExecStartPost = [
            "${pkgs.dnsmasq}/bin/dnsmasq --test --conf-dir=/etc/dnsmasq.d"
            "${pkgs.systemd}/bin/systemctl restart dnsmasq.service"
          ];
        };
      };
      systemd.timers.dnsmasq-china-list-update = lib.mkIf isRouter {
        timerConfig = {
          OnCalendar = "*-*-* 05:10:00";
          Unit = "dnsmasq-china-list-update.service";
        };
        wantedBy = [ "timers.target" ];
      };
      # after sing-box restart or at 05:05:00
      systemd.services.chnroutes2-update = {
        after = [ "sing-box.service" ];
        wants = [ "sing-box.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.nodejs_24}/bin/node ${./update-chnroutes2.ts}";
          ExecStartPost = "${pkgs.nftables}/bin/nft -f /tmp/chnroutes2.nft";
        };
      };
      systemd.timers.chnroutes2-update = {
        timerConfig = {
          OnCalendar = "*-*-* 05:05:00";
          Unit = "chnroutes2-update.service";
        };
        wantedBy = [ "timers.target" ];
      };
      networking.firewall = {
        extraReversePathFilterRules = "meta skuid ${singBoxUser} accept";
        extraInputRules = "meta skuid ${singBoxUser} accept";
        allowedTCPPorts = lib.optionals isRouter [
          9090
          9091
        ];
      };
      networking.nftables = {
        enable = true;
        preCheckRuleset = ''
          sed 's/skuid ${singBoxUser}/skuid nobody/g' -i ruleset.conf
          ${lib.concatMapStringsSep "\n" (
            user: "sed 's/skuid ${user}/skuid nobody/g' -i ruleset.conf"
          ) netbirdUsers}
        '';
        ruleset = ''
          table ip tp {
              set cn_v4 {
                  type ipv4_addr
                  flags interval
              }
              set ipv4_list {
                  type ipv4_addr
                  flags constant, interval
                  auto-merge
                  elements = {
                      0.0.0.0/8,
                      10.0.0.0/8,
                      100.64.0.0/10,
                      127.0.0.0/8,
                      169.254.0.0/16,
                      172.16.0.0/12,
                      192.0.0.0/24,
                      192.0.2.0/24,
                      192.88.99.0/24,
                      192.168.0.0/16,
                      198.18.0.0/15,
                      198.51.100.0/24,
                      203.0.113.0/24,
                      224.0.0.0/3
                  }
              }

              chain prerouting {
                  type filter hook prerouting priority mangle;
                  # meta l4proto { tcp, udp } th dport 53 tproxy to 127.0.0.1:12345 meta mark set ${mark} accept
                  ${lib.optionalString (!isRouter) "meta mark != ${mark} accept"}
                  ${lib.optionalString (
                    !isRouter
                  ) "meta l4proto { tcp, udp } th dport 53 tproxy to 127.0.0.1:12345 accept"}
                  ip daddr @ipv4_list accept
                  ip daddr @cn_v4 accept
                  meta l4proto { tcp, udp } tproxy to 127.0.0.1:12345 meta mark set ${mark} accept
              }

              chain output {
                  type route hook output priority mangle;
                  meta skuid ${singBoxUser} accept
                  ${lib.concatMapStringsSep "\n" (user: "meta skuid ${user} accept") netbirdUsers}
                  ${lib.optionalString hasNetbird "mark ${netbirdMark} accept"}
                  ${lib.optionalString (!isRouter) ''
                    # Let sing-box handle DNS sent to private resolvers, but keep loopback DNS local.
                    ip daddr != 127.0.0.0/8 meta l4proto { tcp, udp } th dport 53 meta mark set ${mark} accept
                  ''}
                  # meta l4proto { tcp, udp } th dport 53 meta mark set ${mark} accept
                  ip daddr @ipv4_list accept
                  ip daddr @cn_v4 accept
                  meta l4proto { tcp, udp } meta mark set ${mark} accept
              }
          }
        '';
      };
      systemd.network = {
        enable = true;
        config.networkConfig = {
          ManageForeignRoutingPolicyRules = false;
          ManageForeignRoutes = false;
        };
        networks = {
          "route" = {
            matchConfig.Name = "lo";
            routingPolicyRules = [
              {
                FirewallMark = mark;
                Table = 100;
                Family = if isRouter then "both" else "ipv4";
              }
            ];
            routes = [
              {
                Table = 100;
                Destination = "0.0.0.0/0";
                Type = "local";
              }
            ];
          };
        };
      };
    }
  );
}
