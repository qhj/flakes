{ config, ... }:

{
  sops.secrets."vaultwarden/client_id" = { };
  sops.secrets."vaultwarden/client_secret" = { };
  sops.templates.vwEnvfile = {
    content = ''
      SSO_CLIENT_ID=${config.sops.placeholder."vaultwarden/client_id"}
      SSO_CLIENT_SECRET=${config.sops.placeholder."vaultwarden/client_secret"}
    '';
  };
  services.vaultwarden = {
    enable = true;
    config = {
      SIGNUPS_ALLOWED = false;
      EMERGENCY_ACCESS_ALLOWED = false;
      ORG_CREATION_USERS = "none";
      DOMAIN = "https://vw.qhj.moe";
      ROCKET_ADDRESS = "127.0.0.1";
      SSO_ENABLED = true;
      SSO_ONLY = true;
      SSO_AUTHORITY = "https://id.qhj.moe";
    };
    environmentFile = [
      config.sops.templates.vwEnvfile.path
    ];
  };
}
