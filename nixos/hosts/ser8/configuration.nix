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
  services.xserver.enable = true;

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

  networking.hostName = "ser8";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Shanghai";
  programs.fish = {
    enable = true;
  };
  programs.firefox.enable = true;
  programs.firefox.preferences = {
    "browser.tabs.inTitlebar" = 0;
    "ui.key.menuAccessKeyFocuses" = false;
  };
  users = {
    groups.qhj.gid = 1000;
    users.qhj = {
      isNormalUser = true;
      group = "qhj";
      extraGroups = [
        "wheel"
        (lib.mkIf config.hardware.i2c.enable "i2c")
      ];
      shell = pkgs.fish;
    };
  };
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
      ];
      waylandFrontend = true;
    };
  };
  environment.systemPackages = with pkgs; [
    fastfetch
    helix
    file
    noto-fonts-cjk-serif
    noto-fonts-cjk-sans
    telegram-desktop
    moonlight-qt
    wl-clipboard
    ghostty
    (
      let
        noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      in
      # add gsettings-desktop-schemas to XDG_DATA_DIRS
      noctalia.overrideAttrs (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
          pkgs.wrapGAppsHook3
        ];
        # https://nixos.org/manual/nixpkgs/stable/#ssec-gnome-common-issues-double-wrapped
        dontWrapGApps = true;
        preFixup = (oldAttrs.preFixup or [ ]) + ''
          qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
        '';
      })
    )
    (writeShellApplication {
      name = "auto-dark";
      runtimeInputs = [ glib ];
      text = ''
        gsettings set org.gnome.desktop.interface color-scheme "$([ "$1" = true ] && printf 'prefer-dark' || printf 'prefer-light')"

        # needed for some apps like Remmina
        gsettings set org.gnome.desktop.interface gtk-theme "$([ "$1" == true ] && printf 'Adwaita-dark' || printf 'Adwaita')"
      '';
    })
    ddcutil
    gpu-screen-recorder
    gnome-themes-extra
    glib
  ];
  fonts.fontconfig = {
    defaultFonts = {
      serif = [
        "Noto Serif CJK SC"
      ];
      sansSerif = [
        "Noto Sans CJK SC"
      ];
    };
  };
  hardware.bluetooth.enable = true;
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  sops = {
    defaultSopsFile = "${secrets-path}/ser8.yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };
  sops.secrets."dae/subscription" = {
    mode = "0400";
  };
  sops.templates.dae-config = {
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
          policy: min_moving_avg
        }
      }

      # See https://github.com/daeuniverse/dae/blob/main/docs/en/configuration/routing.md for full examples.
      routing {
        pname(NetworkManager) -> direct
        dip(224.0.0.0/3, 'ff00::/8') -> direct

        ### Write your rules below.

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
  services.udev.packages = with pkgs; [ canokeys-udev-rules ];
  programs.ssh.startAgent = true;
  services.netbird.enable = true;
  programs.niri.enable = true;
  hardware.i2c.enable = true;

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/desktop/wm/preferences".button-layout = "";
      };
    }
  ];
  services.gnome.gcr-ssh-agent.enable = false;
}
