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
    fishPlugins = import ./fish-plugins.nix {
      inherit final prev;
    };
    sunshine = import ./sunshine.nix {
      inherit final prev;
    };
    libfido2HidOnly = import ./libfido2.nix {
      inherit prev;
    };
  };
}
