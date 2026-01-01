# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./lanzaboote.nix
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
  services.openssh.enable = true;

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

  networking.hostName = "tx";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Shanghai";
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
  };
  programs.firefox.enable = true;
  programs.firefox.preferences = {
    "browser.tabs.inTitlebar" = 0;
  };
  programs.adb.enable = true;
  users = {
    groups.qhj.gid = 1000;
    users.qhj = {
      isNormalUser = true;
      group = "qhj";
      extraGroups = [
        "wheel"
        "adbusers"
        (lib.mkIf config.virtualisation.libvirtd.enable "libvirtd")
      ];
      shell = pkgs.fish;
    };
  };
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.settings = {
  #   Autologin = {
  #     Session = "plasma.desktop";
  #     User = "qhj";
  #   };
  # };
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
    helix
    #fastfetch
    file
    tree
    git
    bat
    noto-fonts-cjk-serif
    noto-fonts-cjk-sans
    fantasque-sans-mono
    telegram-desktop
    wl-clipboard
    waydroid-script
    chromium
    moonlight-qt
    # chiaki-ng
    # looking-glass-client
    mpv
    ghostty
    obs-studio
  ];
  fonts.fontconfig = {
    defaultFonts = {
      serif = [
        "Noto Serif CJK SC"
      ];
      sansSerif = [
        "Noto Sans CJK SC"
      ];
      monospace = [
        "Fantasque Sans Mono"
      ];
    };
  };
  hardware.bluetooth.enable = true;
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
    ];
  };
  virtualisation.waydroid.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  nixpkgs.config.chromium.commandLineArgs = "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo";
  # services.fprintd.enable = true;

  environment.shellAliases = with pkgs; {
    ff = "${fastfetch}/bin/fastfetch";
    # zed = "${zed-editor}/bin/zeditor";
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        # verbatimConfig = ''
        #   cgroup_device_acl = [
        #     "/dev/null", "/dev/full", "/dev/zero",
        #     "/dev/random", "/dev/urandom",
        #     "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
        #     "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
        #     "/dev/kvmfr0"
        #   ]
        # '';
      };
      # hooks.qemu = {
      #   isolcpus-hook = pkgs.writers.writeBash "isolcpus" ''
      #     #!/bin/sh

      #     command=$2

      #     if [ "$command" = "started" ]; then
      #         systemctl set-property --runtime -- system.slice AllowedCPUs=4-15
      #         systemctl set-property --runtime -- user.slice AllowedCPUs=4-15
      #         systemctl set-property --runtime -- init.scope AllowedCPUs=4-15
      #     elif [ "$command" = "release" ]; then
      #         systemctl set-property --runtime -- system.slice AllowedCPUs=0-23
      #         systemctl set-property --runtime -- user.slice AllowedCPUs=0-23
      #         systemctl set-property --runtime -- init.scope AllowedCPUs=0-23
      #     fi
      #   '';
      # };
    };
  };
  programs.virt-manager.enable = true;

  # boot = {
  #   kernelParams = [
  #     "intel_iommu=on"
  #     # Arc A770
  #     "vfio-pci.ids=8086:56a0,8086:4f90"
  #   ];
  #   extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
  #   kernelModules = [
  #     "vfio_pci"
  #     "vfio"
  #     "vfio_iommu_type1"
  #     "kvmfr"
  #   ];
  #   extraModprobeConfig = ''
  #     options kvmfr static_size_mb=256
  #   '';
  #   postBootCommands = ''
  #     DEV="0000:08:00.0"
  #     echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  #     modprobe -i vfio-pci
  #   '';
  # };
  networking.bridges.br0.interfaces = [ "enp9s0" ];
  networking.interfaces.br0.useDHCP = true;

  # services.udev.extraRules = ''
  #   SUBSYSTEM=="kvmfr", OWNER="qhj", GROUP="libvirtd", MODE="0660"
  # '';
  # environment.etc."looking-glass-client.ini".text = ''
  #   [app]
  #   shmFile=/dev/kvmfr0
  # '';

  swapDevices = [ { device = "/swap/swapfile"; } ];

  boot.initrd.systemd.enable = true;

  services.udev.packages = with pkgs; [ canokeys-udev-rules sunshine ];
  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host 192.168.77.1
        ForwardAgent yes
    '';
  };
  networking.interfaces.enp9s0.wakeOnLan = {
    enable = true;
  };

  networking.firewall =
  let
    generatePorts = port: offsets: map (offset: port + offset) offsets;
    defaultPort = 47989;
  in {
    allowedTCPPorts = generatePorts defaultPort [
      (-5)
      0
      1
      21
    ];
    allowedUDPPorts = generatePorts defaultPort [
      9
      10
      11
      13
      21
    ];
  };
  boot.kernelModules = [ "uinput" ];
  services.avahi = {
    enable = lib.mkDefault true;
    publish = {
      enable = lib.mkDefault true;
    };
  };
  systemd.services.sunshine = {
    description = "Self-hosted game stream host for Moonlight";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # services.sunshine = {
  #   enable = true;
  #   autoStart = true;
  #   openFirewall = true;
  #   capSysAdmin = true;
  # };

  virtualisation.podman.enable = true;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };
}
