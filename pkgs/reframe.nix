{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  cmake,
  glib,
  systemd,
  libdrm,
  libepoxy,
  libvncserver,
  libxkbcommon,
}:

stdenv.mkDerivation rec {
  pname = "reframe";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "AlynxZhou";
    repo = "reframe";
    rev = "v${version}";
    hash = "sha256-+1mL/zy3rssGpdEbkOT9WjHS0BganFTwLvqAlBxNRgs=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    cmake
  ];

  buildInputs = [
    glib
    systemd
    libdrm
    libepoxy
    libvncserver
    libxkbcommon
  ];

  mesonFlags = [
    "-Dsystemunitdir=${placeholder "out"}/lib/systemd/system"
    "-Dsysusersdir=${placeholder "out"}/lib/sysusers.d"
  ];

  postInstall = ''
    substituteInPlace $out/lib/systemd/system/*.service --replace-fail "--config=etc" "--config=/etc"
  '';
  

  meta = with lib; {
    description = "DRM/KMS based remote desktop for Linux that supports Wayland/NVIDIA/headless/login";
    homepage = "https://github.com/AlynxZhou/reframe";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
