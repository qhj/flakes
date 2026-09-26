{ lib, ... }:

{
  services.xserver.enable = true;
  services.displayManager = {
    sddm.enable = true;
    defaultSession = lib.mkForce "plasma";
  };
  services.desktopManager.plasma6.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  programs.firefox = {
    enable = true;
    preferences = {
      "browser.tabs.inTitlebar" = 0;
      "ui.key.menuAccessKeyFocuses" = false;
    };
  };
}
