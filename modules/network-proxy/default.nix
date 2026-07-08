{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.qhj.network-proxy = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.qhj.network-proxy.enable (
    let
      singBoxUser = config.systemd.services.sing-box.serviceConfig.User;
      netbirdClientUser = config.systemd.services.netbird-client.serviceConfig.User;
      mark = "7";
      netbirdMark = "0x1bd00";
    in
    {
      sops.secrets."sing-box/input-file" = { };
      services.sing-box.enable = true;
      systemd.services.sing-box = {
        preStart = "${pkgs.nodejs_24}/bin/node ${./index.ts} -i ${
          config.sops.secrets."sing-box/input-file".path
        } -o /etc/sing-box/config.json";
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
      systemd.services.dnsmasq-china-list-update = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.nodejs_24}/bin/node ${./update-dnsmasq-china-list.ts}";
          ExecStartPost = [
            "${pkgs.dnsmasq}/bin/dnsmasq --test --conf-dir=/etc/dnsmasq.d"
            "${pkgs.systemd}/bin/systemctl restart dnsmasq.service"
          ];
        };
      };
      systemd.timers.dnsmasq-china-list-update = {
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
        allowedTCPPorts = [ 9090 ];
      };
      networking.nftables = {
        enable = true;
        preCheckRuleset = ''
          sed 's/skuid ${singBoxUser}/skuid nobody/g' -i ruleset.conf
          sed 's/skuid ${netbirdClientUser}/skuid nobody/g' -i ruleset.conf
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
                  ip daddr @ipv4_list accept
                  ip daddr @cn_v4 accept
                  meta l4proto { tcp, udp } tproxy to 127.0.0.1:12345 meta mark set ${mark} accept
              }

              chain output {
                  type route hook output priority mangle;
                  meta skuid ${singBoxUser} accept
                  # direct to api.netbird.io
                  meta skuid ${netbirdClientUser} accept;
                  # needed for network routes
                  mark ${netbirdMark} accept
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
                Family = "both";
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
