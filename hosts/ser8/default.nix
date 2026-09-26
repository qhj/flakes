{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/base.nix
    ../../profiles/users/qhj.nix
    ../../profiles/ssh-client.nix
    ../../profiles/desktop/plasma.nix
    ../../profiles/desktop/fonts.nix
    ../../profiles/desktop/fcitx5.nix
    ../../profiles/lanzaboote.nix
    ../../profiles/desktop/niri
  ];

  system.stateVersion = "24.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ser8";
  users.users.qhj.extraGroups = [
    (lib.mkIf config.hardware.i2c.enable "i2c")
  ];
  environment.systemPackages = with pkgs; [
    helix
    file
    telegram-desktop
    moonlight-qt
    wl-clipboard
    ghostty
  ];
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  sops = {
    defaultSopsFile = ../../ser8.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };
  services.udev.packages = with pkgs; [ canokeys-udev-rules ];
  services.netbird.enable = true;
}
