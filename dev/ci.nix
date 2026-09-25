{ pkgs }:

pkgs.mkShellNoCC {
  packages = with pkgs; [
    git
    nixfmt
    nodejs_24
    typescript
    pnpm
    biome
  ];
}
