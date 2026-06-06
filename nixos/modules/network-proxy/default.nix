{ lib, config, ... }:
{
  options.network-proxy = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.network-proxy.enable (
    let
      singBoxUser = config.systemd.services.sing-box.serviceConfig.User;
      netbirdClientUser = config.systemd.services.netbird-client.serviceConfig.User;
      mark = "7";
      netbirdMark = "0x1bd00";
    in
    {
      sops.secrets."sing-box/subscription".owner = "sing-box";
      sops.secrets."sing-box/ips".owner = "sing-box";
      services.sing-box = {
        enable = true;
        subscriptionUrlFile = config.sops.secrets."sing-box/subscription".path;
        ipFile = config.sops.secrets."sing-box/ips".path;
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
                  meta l4proto { tcp, udp } th dport 53 tproxy to 127.0.0.1:12345 meta mark set ${mark} accept
                  ip daddr @ipv4_list accept
                  meta l4proto { tcp, udp } tproxy to 127.0.0.1:12345 meta mark set ${mark} accept
              }

              chain output {
                  type route hook output priority mangle;
                  meta skuid ${singBoxUser} accept
                  # direct to api.netbird.io
                  meta skuid ${netbirdClientUser} meta nftrace set 1 accept;
                  # needed for network routes
                  mark ${netbirdMark} accept
                  meta l4proto { tcp, udp } th dport 53 meta mark set ${mark} accept
                  ip daddr @ipv4_list accept
                  meta l4proto { tcp, udp } meta mark set ${mark} accept
              }
          }
        '';
      };
      systemd.network = {
        enable = true;
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
