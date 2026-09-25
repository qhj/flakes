{
  wrapNeovimUnstable,
  neovim-unwrapped,
  vimPlugins,
}:

wrapNeovimUnstable neovim-unwrapped {
  # Let Neovim load init.lua from XDG_CONFIG_HOME instead of setting VIMINIT.
  wrapRc = false;
  plugins = [
    vimPlugins.lz-n
  ]
  ++
    map
      (plugin: {
        inherit plugin;
        optional = true;
      })
      (
        with vimPlugins;
        [
          snacks-nvim
          blink-cmp
          noice-nvim
          which-key-nvim
        ]
      );
}
