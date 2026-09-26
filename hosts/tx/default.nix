{
  pkgs,
  lib,
  config,
  overlays,
  maidModule,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/base.nix
    ../../profiles/users/qhj.nix
    ../../profiles/ssh-client.nix
    ../../profiles/ssh-keys.nix
    ../../profiles/desktop/plasma.nix
    ../../profiles/desktop/fonts.nix
    ../../profiles/desktop/fcitx5.nix
    ../../profiles/desktop/ghostty.nix
    ../../profiles/desktop/vscodium.nix
    ../../profiles/lanzaboote.nix
    ../../profiles/desktop/niri
    (import ./dev-container.nix { inherit overlays maidModule; })
    ../../modules/sunshine.nix
    ./maid.nix
  ];

  system.stateVersion = "24.11";

  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh.enable = true;

  networking.hostName = "tx";
  users.users.qhj.extraGroups = [
    (lib.mkIf config.virtualisation.libvirtd.enable "libvirtd")
    (lib.mkIf config.hardware.i2c.enable "i2c")
  ];
  environment.systemPackages = with pkgs; [
    neovim
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
    obs-studio
    android-tools
    dig
    flameshot
    mpvpaper
    waydroid-helper
  ];
  nix.settings.substituters = [ "https://mirrors.cernet.edu.cn/nix-channels/store" ];
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
  programs.ssh.package = pkgs.openssh.override {
    libfido2 = pkgs.libfido2HidOnly;
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
}
