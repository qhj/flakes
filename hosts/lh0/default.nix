{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/base.nix
    ../../profiles/users/qhj.nix
    ../../profiles/ssh-keys.nix
  ];

  system.stateVersion = "22.11";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "lh0";

  services.openssh = {
    enable = true;
    extraConfig = ''
      ClientAliveInterval 30
      ClientAliveCountMax 10
    '';
  };

  # networking.firewall.allowedTCPPorts = [
  #   80
  #   443
  # ];
}
