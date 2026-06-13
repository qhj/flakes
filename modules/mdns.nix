{ lib, config, ... }:
{
  options.qhj.mdns = {
    enable = lib.mkEnableOption "";
  };
  config = lib.mkIf config.qhj.mdns.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };
  };
}
