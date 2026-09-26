{ overlays, maidModule }:
{ ... }:

{
  containers.dev = {
    config =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        nixpkgs.overlays = overlays;
        imports = [
          maidModule
          ../../profiles/fish
          ../../profiles/helix.nix
        ];
        system.stateVersion = "26.11";
        boot.isNspawnContainer = true;
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        environment.systemPackages = with pkgs; [
          git
          openvscode-server
        ];
        programs.ssh.startAgent = true;
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
