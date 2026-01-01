{ config, ... }:

{
  networking.firewall.allowedTCPPorts = [ 7000 ];
  sops.secrets.frpAuthToken = {};
  sops.templates.envfile = {
    content = ''
      FRP_AUTH_TOKEN=${config.sops.placeholder.frpAuthToken}
    '';
  };
  services.frp.instances = {
    lh0 = {
      enable = true;
      role = "server";
      settings = {
        bindPort = 7000;
        auth.token = "{{ .Envs.FRP_AUTH_TOKEN }}";
      };
      environmentFiles = [
        config.sops.templates.envfile.path
      ];
    };
  };

  services.caddy.virtualHosts."id.qhj.moe".extraConfig = ''
    reverse_proxy http://localhost:1411
  '';
}
