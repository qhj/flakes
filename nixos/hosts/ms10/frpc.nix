{ config, ... }:

{
  sops.secrets.frpServerAddr = {};
  sops.secrets.frpAuthToken = {};
  sops.templates.envfile = {
    content = ''
      FRP_SERVER_ADDR=${config.sops.placeholder.frpServerAddr}
      FRP_AUTH_TOKEN=${config.sops.placeholder.frpAuthToken}
    '';
  };
  services.frp.instances = {
    ms10 = {
      enable = true;
      role = "client";
      settings = {
        auth.token = "{{ .Envs.FRP_AUTH_TOKEN }}";
        proxies = [
          {
            name = "idp";
            type = "tcp";
            plugin = {
              type = "unix_domain_socket";
              unixPath = "/run/pocket-id/sock";
            };
            remotePort = 1411;
          }
          {
            name = "vw";
            type = "tcp";
            localPort = 8000;
            remotePort = 8000;
          }
        ];
        serverAddr = "{{ .Envs.FRP_SERVER_ADDR }}";
        serverPort = 7000;
      };
      environmentFiles = [
        config.sops.templates.envfile.path
      ];
    };
  };
}
