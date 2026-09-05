{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/lanzaboote.nix
    (import ../../modules/niri { inherit inputs lib; })
    ../../modules/fish
    ../../modules/sunshine.nix
  ];

  qhj.fish.enable = true;

  system.stateVersion = "24.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.enable = true;
  services.openssh.enable = true;

  networking.hostName = "tx";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Shanghai";
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
        (lib.mkIf config.virtualisation.libvirtd.enable "libvirtd")
        (lib.mkIf config.hardware.i2c.enable "i2c")
      ];
      shell = lib.mkIf config.programs.fish.enable pkgs.fish;
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
    neovim
    helix
    #fastfetch
    file
    tree
    git
    bat
    telegram-desktop
    wl-clipboard
    chromium
    moonlight-qt
    # chiaki-ng
    # looking-glass-client
    mpv
    ghostty
    obs-studio
    android-tools
    dig
    flameshot
    mpvpaper
    waydroid-helper
  ];
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans-static
    noto-fonts-cjk-serif-static
    fantasque-sans-mono
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
        "Noto Sans Mono CJK SC"
      ];
    };
  };
  hardware.bluetooth.enable = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
    ];
  };
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };
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

  services.udev.packages = with pkgs; [
    canokeys-udev-rules
  ];
  programs.ssh = {
    package = pkgs.openssh.override {
      libfido2 = pkgs.libfido2HidOnly;
    };
    startAgent = true;
    extraConfig = ''
      Host *
        SetEnv TERM=xterm-256color
      Host 192.168.77.1
        ForwardAgent yes
      Host github.com
        Hostname ssh.github.com
        Port 443
    '';
  };
  networking.interfaces.enp9s0.wakeOnLan = {
    enable = true;
  };

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

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  qhj.sunshine.enable = true;
  services.pcscd.enable = true;

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      dwproton-bin
    ];
    protontricks.enable = true;
    extraPackages = with pkgs; [
      mangohud
    ];
  };
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
    ];
  services.displayManager.defaultSession = lib.mkForce "plasma";
}
