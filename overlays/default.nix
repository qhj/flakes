{
  additions =
    final: _prev:
    _prev.lib.packagesFromDirectoryRecursive {
      inherit (_prev) callPackage;
      directory = ../pkgs;
    };
  modifications = final: prev: {
    helix = import ./helix.nix {
      inherit final prev;
    };
    neovim = import ./neovim {
      inherit final prev;
    };
  };
}
