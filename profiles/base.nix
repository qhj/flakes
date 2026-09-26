{ lib, ... }:

{
  imports = [ ./fish ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = lib.mkDefault "Asia/Shanghai";
}
