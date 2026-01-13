{ final, prev }:

final.symlinkJoin {
  name = "helix";
  paths = [ prev.helix ];
  buildInputs = [ final.makeWrapper ];
  postBuild =
    let
      config = final.writers.writeTOML "helix-config" {
        editor = {
          completion-timeout = 5;
          preview-completion-insert = false;
        };
      };
    in
  ''
    wrapProgram $out/bin/hx --add-flags "-c ${config}"
  '';
}

