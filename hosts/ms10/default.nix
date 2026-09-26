{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/base.nix
    ../../profiles/users/qhj.nix
    ../../profiles/ssh-keys.nix
    ./postgresql.nix
    ./pocket-id.nix
    ./miniflux.nix
    ./vaultwarden.nix
    ./cloudflared.nix
  ];

  system.stateVersion = "22.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";

  services.openssh.enable = true;

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
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/music";
      Address = "192.168.77.2";
    };
    openFirewall = true;
  };
  services.caddy = {
    enable = true;
    virtualHosts."http://feishin.ms10.lan".extraConfig =
      let
        feishin-web = pkgs.feishin-web.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace src/renderer/themes/use-app-theme.ts \
              --replace-warn '"Noto Sans JP", "Noto Sans Hebrew"' \
                             '"Noto Sans Hebrew"'
          '';
        });
      in
      ''
        root ${feishin-web}
        file_server
      '';
  };
  networking.firewall.allowedTCPPorts = [
    80
  ];
}
