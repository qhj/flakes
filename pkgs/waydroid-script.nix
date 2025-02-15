{ stdenv, fetchFromGitHub, python3 }:

stdenv.mkDerivation {
  name = "waydroid-script";

  src = fetchFromGitHub {
    owner = "casualsnek";
    repo = "waydroid_script";
    rev = "main";
    hash = "sha256-OiZO62cvsFyCUPGpWjhxVm8fZlulhccKylOCX/nEyJU=";
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
