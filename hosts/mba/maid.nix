{ ... }: {
  users.users.qhj.maid = {
    file.xdg_config."noctalia/config.toml".text = ''
      [include]
      files = ["/etc/noctalia/config.toml"]

      [plugins]
      enabled = ["noctalia/screen_recorder", "local/hostname"]

      [[bar.default.capsule_group]]
      id = "g1"
      members = [ "network_rx", "network_tx" ]
    '';

    file.xdg_config."umbriel/config.toml".text = ''
      [include]
      files = ["/etc/umbriel/config.toml"]

      [output.eDP-1]
      scale = 1.777778
    '';
  };
}
