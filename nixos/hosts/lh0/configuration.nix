{ inputs, pkgs, ...}:

let
  secrets-path = toString inputs.secrets;
in {
  imports = [
    ./hardware-configuration.nix
    ./frps.nix
  ];

  system.stateVersion = "22.11";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  time.timeZone = "Asia/Shanghai";

  networking.hostName = "lh0";

  services.openssh = {
    enable = true;
    extraConfig = ''
      ClientAliveInterval 30
      ClientAliveCountMax 10
    '';
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  programs.fish.enable = true;
  users = {
    groups.qhj.gid = 1000;
    users.qhj = {
      isNormalUser = true;
      group = "qhj";
      extraGroups = [ "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJLZ6a8qWKfuJHeFvLBuBAvIasbrBn1nNw50EYA/Hr0EAAAABHNzaDo="
      ];
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJLZ6a8qWKfuJHeFvLBuBAvIasbrBn1nNw50EYA/Hr0EAAAABHNzaDo="
  ];

  sops = {
    defaultSopsFile = "${secrets-path}/frp.yaml";
    secrets = {
      frpAuthToken = {
        format = "yaml";
        sopsFile = "${secrets-path}/frp.yaml";
      };
    };
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };

  environment.systemPackages = with pkgs; [
    fastfetch
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.caddy = {
    enable = true;
  };
}
