{
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "fish-tide-hostname";
  version = "1.0.0";

  src = ./_tide_item_hostname.fish;
  dontUnpack = true;

  postInstall = ''
    mkdir -p $out/share/fish/vendor_functions.d/
    cp -R $src $out/share/fish/vendor_functions.d/_tide_item_hostname.fish
  '';

  meta = {
    license = lib.licenses.mit;
  };
}
