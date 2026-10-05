{ config, ... }: {
  users.users.qhj.maid = {
    file.xdg_config."autostart/netbird.desktop".source =
      "${config.services.netbird.clients.client.wrapper}/share/applications/netbird.desktop";

    file.xdg_config."noctalia/config.toml".text = ''
      [include]
      files = ["/etc/noctalia/config.toml"]

      [plugins]
      enabled = ["noctalia/screen_recorder", "local/hostname"]
    '';

    file.xdg_config."umbriel/config.toml".text = ''
      [include]
      files = ["/etc/umbriel/config.toml"]

      [keybinds]
      "XF86MonBrightnessDown" = "spawn:noctalia msg brightness-down"
      "XF86MonBrightnessUp" = "spawn:noctalia msg brightness-up"
      "XF86AudioMicMute" = { action = "spawn:noctalia msg mic-mute", repeat = false }
      "XF86AudioPrev" = "spawn:noctalia msg media previous"
      "XF86AudioPlay" = { action = "spawn:noctalia msg media toggle", repeat = false }
      "XF86AudioNext" = "spawn:noctalia msg media next"
      "XF86AudioMute" = { action = "spawn:noctalia msg volume-mute", repeat = false }
      "XF86AudioLowerVolume" = "spawn:noctalia msg volume-down"
      "XF86AudioRaiseVolume" = "spawn:noctalia msg volume-up"

      [output.eDP-1]
      scale = 1.777778
    '';
  };
}
