{
  config,
  lib,
  ...
}:

{
  options.qhj.fish.enable = lib.mkEnableOption "the custom Fish shell configuration";

  config = lib.mkIf config.qhj.fish.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = builtins.readFile ./prompt.fish;
    };
  };
}
