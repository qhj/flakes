{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/lanzaboote.nix
    (import ../../modules/niri { inherit inputs; })
    ../../modules/fish.nix
  ];

  system.stateVersion = "24.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.enable = true;

  networking.hostName = "ser8";
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
    fastfetch
    helix
    file
    noto-fonts-cjk-serif
    noto-fonts-cjk-sans
    fantasque-sans-mono
    telegram-desktop
    moonlight-qt
    wl-clipboard
    ghostty
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
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  sops = {
    defaultSopsFile = ../../ser8.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };
  services.udev.packages = with pkgs; [ canokeys-udev-rules ];
  programs.ssh = {
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
  services.netbird.enable = true;
}
