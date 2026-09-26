{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.groups.qhj.gid = 1000;
  users.users.qhj = {
    isNormalUser = true;
    group = "qhj";
    extraGroups = lib.mkBefore [ "wheel" ];
    shell = lib.mkIf config.programs.fish.enable pkgs.fish;
  };
}
