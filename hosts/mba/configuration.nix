{
  inputs,
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
    ../../modules/fish
    inputs.umbriel.nixosModules.default
  ];

  qhj.fish.enable = true;

  system.stateVersion = "26.11";

  hardware.asahi.enable = true;
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
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Shanghai";

  programs.firefox.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  networking.networkmanager.wifi.backend = "iwd";
  programs.fish.enable = true;
  users = {
    groups.qhj.gid = 1000;
    users.qhj = {
      isNormalUser = true;
      group = "qhj";
      extraGroups = [ "wheel" ];
      shell = pkgs.fish;
    };
  };
  environment.systemPackages = with pkgs; [
    helix
    fastfetch
    ghostty
    telegram-desktop
  ];
  services.udev.packages = with pkgs; [ canokeys-udev-rules ];
  # Swap Caps Lock and left Control on the built-in keyboard at the evdev layer.
  services.udev.extraHwdb = ''
    evdev:name:Apple SPI Keyboard:*
     KEYBOARD_KEY_70039=leftctrl
     KEYBOARD_KEY_700e0=capslock
  '';
  programs.umbriel = {
    enable = true;
    package =
      inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
        (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [ ./umbriel-default-keybinds.patch ];
        });
  };
  programs.noctalia.enable = true;
  services.displayManager.noctalia-greeter.enable = true;
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
}
