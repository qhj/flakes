{ ... }:

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

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL= "https://id.qhj.moe";
      TRUST_PROXY = true;
      UNIX_SOCKET = "/run/pocket-id/sock";
      UNIX_SOCKET_MODE = "0660";
      DB_PROVIDER = "postgres";
      DB_CONNECTION_STRING = "user=pocket-id dbname=pocket-id host=/run/postgresql";
    };
  };

  systemd.services = {
    pocket-id.serviceConfig.RuntimeDirectory = [ "pocket-id" ];
    pocket-id.serviceConfig.RestrictAddressFamilies = [ "AF_UNIX" ];
    "frp-ms10".serviceConfig.SupplementaryGroups = [ "pocket-id" ];
  };
}
