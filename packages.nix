{ pkgs }:

let
  repoRoot = pkgs.writeShellApplication {
    name = "repo-root";
    runtimeInputs = [ pkgs.git ];
    text = ''
      exec git rev-parse --show-toplevel
    '';
  };
in
{
  repo-root = repoRoot;
  nvim-dev = pkgs.writeShellApplication {
    name = "nvim-dev";
    runtimeInputs = [ pkgs.neovim ];
    text = ''
      FLAKE_ROOT=$(${pkgs.lib.getExe repoRoot})
      XDG_CONFIG_HOME="$FLAKE_ROOT"/pkgs/neovim/config nvim "$@"
    '';
  };
}
