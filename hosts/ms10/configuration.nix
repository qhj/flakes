{
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/fish.nix
    ../../modules/mdns.nix
    ./postgresql.nix
    ./pocket-id.nix
    ./vaultwarden.nix
    ./cloudflared.nix
  ];

  system.stateVersion = "22.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";

  time.timeZone = "Asia/Shanghai";

  services.openssh.enable = true;

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  users = {
    groups.qhj.gid = 1000;
    users.qhj = {
      isNormalUser = true;
      group = "qhj";
      extraGroups = [ "wheel" ];
      shell = lib.mkIf config.programs.fish.enable pkgs.fish;
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJLZ6a8qWKfuJHeFvLBuBAvIasbrBn1nNw50EYA/Hr0EAAAABHNzaDo="
      ];
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJLZ6a8qWKfuJHeFvLBuBAvIasbrBn1nNw50EYA/Hr0EAAAABHNzaDo="
  ];

  networking = {
    hostName = "ms10";
    defaultGateway = "192.168.77.1";
    nameservers = [ "192.168.77.1" ];
    bridges.br0.interfaces = [ "enp3s0f0" ];
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.77.2";
        prefixLength = 24;
      }
    ];
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "br0";
    };
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      nas = {
        path = "/smb";
        writeable = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    virt-manager
  ];

  security.polkit.enable = true;
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
      };
    };
  };
  sops = {
    defaultSopsFile = ../../ms10.yaml;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };
  qhj.mdns.enable = true;
}
