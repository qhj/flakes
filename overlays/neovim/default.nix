{ final, prev }:

(prev.neovim.override {
  configure = {
    packages.paaackage = {
      start = with prev.vimPlugins; [
        lz-n
      ];
      opt = with prev.vimPlugins; [
        snacks-nvim
        blink-cmp
        noice-nvim
        which-key-nvim
      ];
    };
  };
}).overrideAttrs
  (oldAttrs: {
    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ final.makeWrapper ];
    postFixup = (oldAttrs.postFixup or "") + ''
      wrapProgram $out/bin/nvim \
        --set XDG_CONFIG_HOME ${./.}
      substituteInPlace $out/bin/.nvim-wrapped \
        --replace-fail "export VIMINIT=" "# export VIMINIT="
    '';
  })
