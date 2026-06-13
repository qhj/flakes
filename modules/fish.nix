{
  pkgs,
  ...
}:

{
  config = {
    environment.systemPackages = with pkgs; [
      fishPlugins.tide
      fish-tide-hostname
    ];
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting

        contains hostname $tide_left_prompt_items
        or set -U tide_left_prompt_items hostname $tide_left_prompt_items
        set -U tide_hostname_color ffc0cb
        set -U tide_hostname_bg_color normal
      '';
    };
  };
}
