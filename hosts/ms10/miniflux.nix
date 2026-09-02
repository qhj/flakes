{ config, ... }:

{
  sops.secrets."miniflux/client_id" = { };
  sops.secrets."miniflux/client_secret" = { };
  sops.templates.minifluxEnvfile = {
    content = ''
      OAUTH2_CLIENT_ID=${config.sops.placeholder."miniflux/client_id"}
      OAUTH2_CLIENT_SECRET=${config.sops.placeholder."miniflux/client_secret"}
    '';
  };

  services.miniflux = {
    enable = true;
    config = {
      CREATE_ADMIN = false;
      DISABLE_LOCAL_AUTH = 1;
      BASE_URL = "https://feed.qhj.moe/";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_REDIRECT_URL = "https://feed.qhj.moe/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://id.qhj.moe";
      OAUTH2_USER_CREATION = 1;
    };
  };

  systemd.services.miniflux.serviceConfig.EnvironmentFile =
    config.sops.templates.minifluxEnvfile.path;
}
