{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ghostty ];

  users.users.qhj.maid.file.xdg_config."ghostty/config".text = ''
    theme = dark:Catppuccin Frappe,light:Catppuccin Latte
  '';
}
