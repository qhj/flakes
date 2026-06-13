{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
  };
  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
  };
}
