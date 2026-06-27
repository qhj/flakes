# https://github.com/MidAutumnMoon/TaysiTsuki/blob/8826e3263b6c8ca9290a4da49b9bcb5b68bd8d39/nixos/documentation/module.nix

{
  documentation.info.enable = false;
  documentation.nixos.enable = false;

  documentation.man.cache = {
    enable = true;
    generateAtRuntime = true;
  };

  environment.variables = {
    MANWIDTH = "80";
    MANROFFOPT = "-P -c";
  };
}
