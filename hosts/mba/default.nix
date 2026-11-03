{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/base.nix
    ../../profiles/nix-cache.nix
    ../../profiles/users/qhj.nix
    ../../profiles/ssh-client.nix
    ../../profiles/pcsc.nix
    ../../profiles/desktop/fonts.nix
    ../../profiles/desktop/fcitx5.nix
    ../../profiles/desktop/firefox.nix
    ../../profiles/desktop/ghostty.nix
    ../../profiles/desktop/vscodium.nix
    ../../profiles/desktop/umbriel
    # ../../modules/network-proxy
    ./maid.nix
  ];

  system.stateVersion = "26.11";

  hardware.asahi.enable = true;
  hardware.asahi.avd.vaapi-support = true;
  hardware.asahi.peripheralFirmwareDirectory = null;
  # /boot/m1n1/boot.bin is stage 2. CHAINLOADING builds are for stage 1
  # and skip the display power-cycle workaround needed with Sequoia system
  # firmware and older OS firmware (otherwise brightness only changes at 0%).
  # Override the boot package directly: Asahi uses a separate package set,
  # so an overlay on the system's pkgs.m1n1 does not affect this binary.
  boot.m1n1Package = config.hardware.asahi.pkgs.m1n1.overrideAttrs (oldAttrs: {
    makeFlags = lib.remove "CHAINLOADING=1" oldAttrs.makeFlags;
  });
  nixpkgs.config.allowUnfreePredicate = package: builtins.elem (lib.getName package) [ "obsidian" ];

  boot.kernelParams = [ "hid_apple.fnmode=2" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = "mba";

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  # sops.secrets."sing-box/input-file" = {
  #   sopsFile = ../../sing-box.yaml;
  #   owner = config.systemd.services.sing-box.serviceConfig.User;
  # };

  # qhj.network-proxy = {
  #   enable = true;
  #   mode = "local";
  #   inputFile = config.sops.secrets."sing-box/input-file".path;
  # };

  networking.networkmanager.wifi.backend = "iwd";
  environment.systemPackages = with pkgs; [
    telegram-desktop
    obsidian
    syncthing
  ];
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      21027
      22000
    ];
  };
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

  services.resolved.enable = true;
  services.netbird.package = pkgs.netbird.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace client/grpc/dialer_generic.go \
        --replace-fail 'if runtime.GOOS == "linux" && os.Geteuid() != 0 {' \
          'if runtime.GOOS == "linux" && os.Geteuid() != 0 && !nbnet.AdvancedRouting() {'
    '';
  });
  services.netbird.clients.client = {
    port = 51820;
    name = "client";
    interface = "wt0";
    bin.suffix = "";
  };
  users.users.qhj.extraGroups = [
    config.systemd.services.netbird-client.serviceConfig.User
  ];
}
