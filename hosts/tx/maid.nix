{ ... }: {
  users.users.qhj.maid = {
    file.xdg_config."MangoHud/MangoHud.conf".text = ''
      position=top-center
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
