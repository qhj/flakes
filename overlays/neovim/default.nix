{ final, prev }:

final.symlinkJoin {
  name = "neovim";
  paths = [ prev.neovim ];
  buildInputs = [ final.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --set XDG_CONFIG_HOME ${./.}
  '';
}
