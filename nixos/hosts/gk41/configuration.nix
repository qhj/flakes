# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  inputs,
  config,
  pkgs,
  ...
}:

let
  secrets-path = toString inputs.secrets;
  secrets = import inputs.secrets;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
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
      };
    };
  };

  programs.fish.enable = true;
  users.groups.qhj.gid = 1000;
  users.users.qhj = {
    isNormalUser = true;
    group = "qhj";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
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
          usepeerdns
          persist
          defaultroute
          noauth
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
      server = [ "114.114.114.114" ];
      dhcp-host = "192.168.77.1";
      dhcp-range = [
        "192.168.77.2,192.168.77.254,12h"
      ];
    };
  };
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  time.timeZone = "Asia/Shanghai";
  networking.firewall.allowedUDPPorts = [
    53
    67
  ];
  nix.settings.experimental-features = "nix-command flakes";

  sops.secrets."dae/subscription" = {
    mode = "0400";
  };
  sops.secrets.server1 = {
    mode = "0400";
  };
  sops.templates.dae-config = {
    restartUnits = [ config.systemd.services.dae.name ];
    content = ''
      global {
        # Bind to LAN and/or WAN as you want. Replace the interface name to your own.
        lan_interface: br0
        wan_interface: auto # Use "auto" to auto detect WAN interface.

        log_level: info
        allow_insecure: false
        auto_config_kernel_parameter: true
      }

      subscription {
        "${config.sops.placeholder."dae/subscription"}"
      }

      # See https://github.com/daeuniverse/dae/blob/main/docs/en/configuration/dns.md for full examples.
      dns {
        upstream {
          googledns: 'tcp+udp://dns.google:53'
          alidns: 'udp://223.5.5.5:53'
        }
        routing {
          request {
            qtype(https) -> reject
            fallback: alidns
          }
          response {
            upstream(googledns) -> accept
            ip(geoip:private) && !qname(geosite:cn) -> googledns
            fallback: accept
          }
        }
      }

      group {
        proxy {
          #filter: name(keyword: HK, keyword: SG)
          # policy: min_moving_avg
          policy: fixed(4)
        }
      }

      # See https://github.com/daeuniverse/dae/blob/main/docs/en/configuration/routing.md for full examples.
      routing {
        pname(NetworkManager) -> direct
        dip(224.0.0.0/3, 'ff00::/8') -> direct

        ### Write your rules below.
        dip(${config.sops.placeholder.server1}) -> direct

        # Disable h3 because it usually consumes too much cpu/mem resources.
        l4proto(udp) && dport(443) -> block
        dip(geoip:private) -> direct
        dip(geoip:cn) -> direct
        domain(geosite:cn) -> direct

        fallback: proxy
      }
    '';
    mode = "0400";
  };
  services.dae = {
    enable = true;
    configFile = config.sops.templates.dae-config.path;
  };
  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet pmtu {
        chain forward {
          type filter hook forward priority filter; policy accept;
          oifname "ppp0" tcp flags syn tcp option maxseg size set rt mtu
        }
      }
    '';
  };
  security.pam = {
    rssh.enable = true;
    services.sudo.rssh = true;
  };
  services.netbird.enable = true;
}
