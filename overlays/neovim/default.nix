{ final, prev }:
# let
#   neovimConfig = final.runCommandLocal "neovim-config" { } ''
#     mkdir $out
#     cp -r ${toString ./.}/{init.lua,lua} $out
#   '';

# in
final.symlinkJoin {
  name = "neovim";
  paths = [ prev.neovim ];
  buildInputs = [ final.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --set XDG_CONFIG_HOME ${./.}
  '';
  # postBuild = ''
  #   wrapProgram $out/bin/nvim \
  #     --add-flags '-u' \
  #     --add-flags '${neovimConfig}/init.lua' \
  #     --set NVIM_APPNAME 'nv'
  # '';
}
