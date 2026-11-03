{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ghostty ];

  # KDE uses these settings when launching terminal applications such as Helix.
  environment.etc."xdg/kdeglobals".text = ''
    [General]
    TerminalApplication=${pkgs.ghostty}/bin/ghostty
    TerminalService=com.mitchellh.ghostty.desktop
  '';

  users.users.qhj.maid.file.xdg_config."ghostty/config".text = ''
    theme = dark:Catppuccin Frappe,light:Catppuccin Latte
  '';
}
