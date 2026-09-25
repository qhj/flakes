{
  pkgs,
  repoRoot,
}:

pkgs.mkShellNoCC {
  packages = with pkgs; [
    bashInteractive
    fish
    git
    nixd
    nixfmt
    lua-language-server
    nodejs_24
    typescript
    pnpm
    biome
    codex
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
        jnoortheen.nix-ide
        biomejs.biome
        tombi-toml.tombi
      ];
    })
  ];
  shellHook =
    with pkgs;
    let
      settings = writers.writeJSON "settings.json" {
        "terminal.integrated.defaultProfile.linux" = "fish";
        "explorer.compactFolders" = false;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "nixfmt";
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "editor.formatOnSave" = true;
        "editor.defaultFormatter" = "biomejs.biome";
        "editor.codeActionsOnSave" = {
          "source.organizeImports.biome" = "explicit";
        };
      };
    in
    ''
      export FLAKE_ROOT=$(${pkgs.lib.getExe repoRoot})

      mkdir -p .vscode
      ln -sf ${settings} .vscode/settings.json

      export SHELL=${pkgs.lib.getExe fish}
      exec "$SHELL"
    '';
}
