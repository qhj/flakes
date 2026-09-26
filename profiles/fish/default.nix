{
  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./prompt.fish;
  };
}
