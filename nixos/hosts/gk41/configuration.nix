# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  secrets-path = toString inputs.secrets;
  secrets = import inputs.secrets;
in
{
  disabledModules = [ "services/networking/sing-box.nix" ];
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/network-proxy
    ../../modules/sing-box
    ../../modules/fish.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  #services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  # programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

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
    extraGroups = [ "wheel" ];
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
    defaultSopsFile = "${secrets-path}/gk41.yaml";
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };

  sops.secrets."pppoe/password" = {
    mode = "0400";
  };
  sops.templates.pppoe-pap-secrets = {
    content = ''
      ${secrets.pppoe.username} * ${config.sops.placeholder."pppoe/password"}
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
        config = ''
          plugin pppoe.so
          enp2s0
          name "${secrets.pppoe.username}"
          persist
          defaultroute
          noauth
          # eliminate `Failed to create /etc/ppp/resolv.conf: Read-only file system` error
          #usepeerdns
          # or
          #noresolvconf
        '';
      };
    };
  };
  services.openssh.enable = true;
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "br0";
      bind-interfaces = true;
      server = [ "1.1.1.1" ];
      dhcp-host = "192.168.77.1";
      dhcp-range = [
        "192.168.77.2,192.168.77.254,12h"
      ];
      conf-dir = "/etc/dnsmasq.d";
      log-queries = true;
    };
  };
  systemd.tmpfiles.rules = [ "d /etc/dnsmasq.d 0755 root root -" ];
  systemd.services.dnsmasq-china-list-update = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nodejs_24}/bin/node ${./update-dnsmasq-china-list.ts}";
      ExecStartPost = "${pkgs.systemd}/bin/systemctl restart dnsmasq.service";
    };
  };
  systemd.timers.dnsmasq-china-list-update = {
    timerConfig = {
      OnCalendar = "*-*-* 05:10:00";
      Unit = "dnsmasq-china-list-update.service";
    };
    wantedBy = [ "timers.target" ];
  };
  systemd.services.chnroutes2-update = {
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
  systemd.services.netbird-restart = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart netbird-client.service";
    };
  };
  systemd.timers.netbird-restart = {
    timerConfig = {
      OnCalendar = "*-*-* 02:05:00";
      Unit = "netbird-restart.service";
    };
    wantedBy = [ "timers.target" ];
  };
  network-proxy.enable = true;
}
