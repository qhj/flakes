{ ... }: {
  users.users.qhj.maid = {
    file.xdg_config."nvim".source = ../../pkgs/neovim/config/nvim;

    file.xdg_config."noctalia/config.toml".text = ''
      [include]
      files = ["/etc/noctalia/config.toml"]

      [[shell.session.actions]]
      action = "lock"
      shortcut = "1"

      [[shell.session.actions]]
      action = "logout"
      shortcut = "2"

      [[shell.session.actions]]
      action = "lock_and_suspend"
      shortcut = "3"

      [[shell.session.actions]]
      action = "reboot"
      shortcut = "4"

      [[shell.session.actions]]
      action = "shutdown"
      shortcut = "5"

      [[shell.session.actions]]
      action = "command"
      label = "Windows"
      glyph = "brand-windows"
      command = "systemctl reboot --boot-loader-entry=auto-windows"
      shortcut = "6"
    '';

    file.xdg_config."MangoHud/MangoHud.conf".text = ''
      position=bottom-center
      horizontal
      horizontal_stretch=0
      legacy_layout=0

      font_size=32
      font_size_text=32
      no_small_font

      fps
      fps_metrics=avg,0.01

      gpu_list=1
      gpu_stats
      gpu_temp
      gpu_power

      cpu_stats
      cpu_temp

      procmem
      ram

      blacklist=HYPHelper
    '';
  };
}
