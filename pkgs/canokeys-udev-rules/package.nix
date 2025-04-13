{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "canokeys-udev-rules";
  version = "1.0.0";

  src = ./69-canokeys.rules;
  dontUnpack = true;

  installPhase = ''
    install -D $src $out/lib/udev/rules.d/69-canokeys.rules
  '';
}
