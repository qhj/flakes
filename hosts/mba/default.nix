{
  lib,
  pkgs,
  ...
}:

let
  firmware = pkgs.requireFile {
    name = "firmware.cpio";
    hash = "sha256-ReQiPDax4qL1jZKaiBK7eMvvm7esqqAwc9rZc87SO3Y=";
    message = ''
      nix-store --add-fixed sha256 /boot/vendorfw/firmware.cpio
    '';
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/base.nix
    ../../profiles/users/qhj.nix
    ../../profiles/desktop/fonts.nix
    ../../profiles/desktop/fcitx5.nix
    ../../profiles/desktop/umbriel
    ./maid.nix
  ];

  system.stateVersion = "26.11";

  hardware.asahi.enable = true;
  # /boot/m1n1/boot.bin is stage 2. CHAINLOADING builds are for stage 1
  # and skip the display power-cycle workaround needed with Sequoia system
  # firmware and older OS firmware (otherwise brightness only changes at 0%).
  nixpkgs.overlays = [
    (_final: prev: {
      m1n1 = prev.m1n1.overrideAttrs (oldAttrs: {
        makeFlags = lib.remove "CHAINLOADING=1" oldAttrs.makeFlags;
      });
    })
  ];
  hardware.asahi.peripheralFirmwareDirectory = pkgs.linkFarm "asahi-peripheral-firmware" [
    {
      name = "firmware.cpio";
      path = firmware;
    }
  ];

  nixpkgs.config.allowUnfreePredicate = package: lib.getName package == "firmware.cpio";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = "mba";

  programs.firefox.enable = true;

  networking.networkmanager.wifi.backend = "iwd";
  environment.systemPackages = with pkgs; [
    helix
    telegram-desktop
  ];
  services.udev.packages = with pkgs; [ canokeys-udev-rules ];
  services.udev.extraHwdb = ''
    evdev:name:Apple SPI Keyboard:*
     KEYBOARD_KEY_70039=leftctrl
     KEYBOARD_KEY_700e0=capslock
  '';
  programs.noctalia.recommendedServices.enable = true;
  services.displayManager.noctalia-greeter = {
    enable = true;
    cursorTheme = {
      package = pkgs.adwaita-icon-theme;
    };
    settings.output.scale = 1.777778;
  };
}
