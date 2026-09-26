{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.helix ];

  users.users.qhj.maid.file.xdg_config."helix/config.toml".text = ''
    theme = "base16_transparent"

    [editor]
    completion-timeout = 5
    preview-completion-insert = false
  '';
}
