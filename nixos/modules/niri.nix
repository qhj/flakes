{ config, lib, pkgs, ...}:

{
  config = lib.mkIf config.programs.niri.enable {
    environment.etc."niri/config.kdl".source =
      pkgs.runCommand "niri-base-config.kdl" { preferLocalBuild = true; }
        ''
          echo 'include "${pkgs.niri.src}/resources/default-config.kdl"' > $out
          echo >> $out
          
          echo 'include "extra.kdl"' >> $out
        '';
    environment.etc."niri/extra.kdl".source = pkgs.replaceVars ./extra.kdl {
      polkit-kde-agent-1 = pkgs.kdePackages.polkit-kde-agent-1;
    };
  };
}
