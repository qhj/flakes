{
  additions =
    final: _prev:
    _prev.lib.packagesFromDirectoryRecursive {
      inherit (_prev) callPackage;
      directory = ../pkgs;
    };
  modifications = final: prev: {
    libfido2HidOnly = import ./libfido2.nix {
      inherit prev;
    };
  };
}
