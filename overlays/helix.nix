{ final, prev }:
final.writeShellApplication {
  name = "hx";
  runtimeInputs = [
    prev.helix
  ];
  text =
    let
      config = final.writers.writeTOML "helix-config" {
        editor = {
          completion-timeout = 5;
          preview-completion-insert = false;
        };
      };
    in
    ''
      hx -c ${config} "$@"
    '';
}
