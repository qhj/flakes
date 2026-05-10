{ config, ... }:

{
  services.postgresql = {
    ensureDatabases = [ "pocket-id" ];
    ensureUsers = [
      {
        name = "pocket-id";
        ensureDBOwnership = true;
      }
    ];
  };
  sops.secrets."pocketid/encryption_key" = {};
  sops.templates.pocketIdEnvfile = {
    content = ''
      ENCRYPTION_KEY=${config.sops.placeholder."pocketid/encryption_key"}
    '';
  };

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL= "https://id.qhj.moe";
      TRUST_PROXY = true;
      UNIX_SOCKET = "/run/pocket-id/sock";
      UNIX_SOCKET_MODE = "0660";
      DB_CONNECTION_STRING = "postgresql://localhost/pocket-id?host=/run/postgresql";
    };
    environmentFile = config.sops.templates.pocketIdEnvfile.path;
  };

  systemd.services = {
    pocket-id.serviceConfig.RuntimeDirectory = [ "pocket-id" ];
    pocket-id.serviceConfig.RestrictAddressFamilies = [ "AF_UNIX" ];
    "frp-ms10".serviceConfig.SupplementaryGroups = [ "pocket-id" ];
  };
}
