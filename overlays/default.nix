{
  additions =
    final: _prev:
    _prev.lib.packagesFromDirectoryRecursive {
      inherit (_prev) callPackage;
      directory = ../pkgs;
    };
}
