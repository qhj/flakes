{ ... }: {
  users.users.qhj.maid = {
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

    file.xdg_data."fcitx5/rime/default.custom.yaml".text = ''
      patch:
        __include: rime_ice_suggestion:/
        menu/page_size: 7
        ascii_composer/switch_key/Shift_L: commit_code
        switcher/hotkeys:
          - F4

        schema_list:
          - schema: rime_ice
    '';

    file.xdg_data."fcitx5/rime/rime_ice.custom.yaml".text = ''
      patch:
        switches/@0/reset: 1
    '';

    file.xdg_config."fcitx5/config".text = ''
      [Hotkey/TriggerKeys]
      0=Shift+Shift_R

      [Hotkey/AltTriggerKeys]
      0=Shift+Shift_R

      [Behavior]
      ActiveByDefault=True
    '';
  };
}
