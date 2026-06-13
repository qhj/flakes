{ outputs }:
{ ... }:

{
  containers.dev = {
    bindMounts.projects = {
      hostPath = "/home/qhj/Projects";
      mountPoint = "/home/qhj/Projects";
      isReadOnly = false;
    };
    config =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        nixpkgs.overlays = with outputs.overlays; [
          additions
          modifications
        ];
        imports = [
          ../../modules/fish.nix
        ];
        boot.isNspawnContainer = true;
        nix.settings.experimental-features = "nix-command flakes";
        environment.systemPackages = with pkgs; [
          helix
        ];
        users = {
          groups.qhj.gid = 1000;
          users.qhj = {
            isNormalUser = true;
            group = "qhj";
            shell = lib.mkIf config.programs.fish.enable pkgs.fish;
          };
        };
      };
  };
}
