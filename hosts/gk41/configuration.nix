{
  config,
  pkgs,
  lib,
  ...
}:

{
  disabledModules = [
    "services/networking/pppd.nix"
  ];
  imports = [
    ./hardware-configuration.nix
    ../../modules/network-proxy
    ../../modules/fish.nix
    ./pppd.nix
  ];

  system.stateVersion = "24.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    useDHCP = false;
    hostName = "gk41";
  };
  systemd.network = {
    enable = true;
    netdevs = {
      "25-br0" = {
        netdevConfig = {
          Name = "br0";
          Kind = "bridge";
        };
      };
    };
    networks = {
      "20-wan" = {
        matchConfig.Name = "enp2s0";
        networkConfig = {
          LinkLocalAddressing = "no";
        };
      };
      "25-br0-slaves" = {
        matchConfig.Name = "enp3s0";
        networkConfig = {
          Bridge = "br0";
        };
      };
      "25-br0" = {
        matchConfig.Name = "br0";
        networkConfig = {
          Address = "192.168.77.1/24";
          IPMasquerade = "ipv4";
          LinkLocalAddressing = "no";
        };
      };
      "60-ppp" = {
        matchConfig.Type = "ppp";
        networkConfig.IPv6AcceptRA = false;
      };
    };
  };

  users.groups.qhj.gid = 1000;
  users.users.qhj = {
    isNormalUser = true;
    group = "qhj";
    extraGroups = [
      "wheel"
      config.systemd.services.netbird-client.serviceConfig.User
    ];
    shell = lib.mkIf config.programs.fish.enable pkgs.fish;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJLZ6a8qWKfuJHeFvLBuBAvIasbrBn1nNw50EYA/Hr0EAAAABHNzaDo="
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJLZ6a8qWKfuJHeFvLBuBAvIasbrBn1nNw50EYA/Hr0EAAAABHNzaDo="
  ];
  environment.systemPackages = with pkgs; [
    helix
    fastfetch
    wol
    dig
  ];

  sops = {
    defaultSopsFile = ../../gk41.yaml;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };

  sops.secrets."pppoe/username" = {
    mode = "0400";
  };
  sops.secrets."pppoe/password" = {
    mode = "0400";
  };
  sops.templates.pppoe-pap-secrets = {
    content = ''
      ${config.sops.placeholder."pppoe/username"} * ${config.sops.placeholder."pppoe/password"}
    '';
    mode = "0400";
  };
  sops.templates.pppoe-config = {
    content = ''
      plugin pppoe.so
      enp2s0
      name "${config.sops.placeholder."pppoe/username"}"
      persist
      defaultroute
      noauth
      # eliminate `Failed to create /etc/ppp/resolv.conf: Read-only file system` error
      #usepeerdns
      # or
      #noresolvconf
    '';
    mode = "0400";
  };

  environment.etc."ppp/pap-secrets".source = config.sops.templates.pppoe-pap-secrets.path;
  services.pppd = {
    enable = true;
    peers = {
      provider = {
        autostart = true;
        enable = true;
        configFile = config.sops.templates.pppoe-config.path;
      };
    };
  };
  services.openssh.enable = true;
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = [
        "br0"
        "wt0"
      ];
      bind-interfaces = true;
      server = [ "1.1.1.1" ];
      address = [
        "/gk41.lan/192.168.77.1"
        "/ms10.lan/192.168.77.2"
        "/feishin.ms10.lan/192.168.77.2"
      ];
      dhcp-range = [
        "192.168.77.128,192.168.77.254,12h"
      ];
      local = "/lan/";
      domain = "lan";
      conf-dir = "/etc/dnsmasq.d";
      log-queries = true;
    };
  };
  services.resolved.enable = false;
  systemd.tmpfiles.rules = [ "d /etc/dnsmasq.d 0755 root root -" ];
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  time.timeZone = "Asia/Shanghai";
  networking.firewall.allowedUDPPorts = [
    53
    67
  ];
  nix.settings.experimental-features = "nix-command flakes";

  networking.nftables = {
    enable = true;
    tables = {
      pmtu = {
        enable = true;
        family = "inet";
        content = ''
          chain forward {
            type filter hook forward priority filter; policy accept;
            oifname "ppp0" tcp flags syn tcp option maxseg size set rt mtu
          }
        '';
      };
    };
  };
  security.pam = {
    rssh.enable = true;
    services.sudo.rssh = true;
  };
  services.netbird.clients.client = {
    port = 51820;
    name = "client";
    interface = "wt0";
    bin.suffix = "";
  };
  qhj.network-proxy.enable = true;
}
