{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans-static
    noto-fonts-cjk-serif-static
    fantasque-sans-mono
  ];

  fonts.fontconfig.defaultFonts = {
    serif = [ "Noto Serif CJK SC" ];
    sansSerif = [ "Noto Sans CJK SC" ];
    monospace = [
      "Fantasque Sans Mono"
      "Noto Sans Mono CJK SC"
    ];
  };
}
