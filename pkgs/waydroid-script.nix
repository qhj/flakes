{ stdenv, fetchFromGitHub, python3 }:

stdenv.mkDerivation {
  name = "waydroid-script";

  src = fetchFromGitHub {
    owner = "casualsnek";
    repo = "waydroid_script";
    rev = "fcb15624db0811615ea9800837a836c4777674bf";
    hash = "sha256-Epvl6thT6mJqurZV1FV6Zdd6Kn13ZAC/BUaywVLpOIc=";
  };

  buildInputs = [
    (python3.withPackages(ps: with ps; [ tqdm requests inquirerpy ]))
  ];

  postPatch = ''
    patchShebangs main.py
  '';

  installPhase = ''
    mkdir -p $out/libexec
    cp -r . $out/libexec/waydroid_script
    mkdir -p $out/bin
    ln -s $out/libexec/waydroid_script/main.py $out/bin/waydroid_script
  '';
}
