{ prev, ... }:

prev.fishPlugins.overrideScope (
  fFinal: fPrev: {
    tide = fPrev.tide.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        sed -i '2i\    command -q git; or return\n' $out/share/fish/vendor_functions.d/_tide_item_git.fish
      '';
    });
  }
)
