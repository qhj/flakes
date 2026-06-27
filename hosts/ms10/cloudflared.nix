{ config, ... }:
{

  sops.secrets."cftunnel/credentials" = {
    mode = "0400";
  };
  services.cloudflared = {
    enable = true;
    tunnels = {
      "f8619a65-0937-4f8e-9525-07c642b9cb94" = {
        credentialsFile = config.sops.secrets."cftunnel/credentials".path;
        default = "http_status:404";
        ingress = {
          "id.qhj.moe" = "http://127.0.0.1:1411";
          "vw.qhj.moe" = "http://127.0.0.1:8000";
        };
      };
    };
  };
}
