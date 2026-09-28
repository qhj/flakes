{ pkgs, ... }:
{
  programs.ssh = {
    package = pkgs.openssh.override {
      libfido2 = pkgs.libfido2HidOnly;
    };
    extraConfig = ''
      Host *
        SetEnv TERM=xterm-256color
      Host 192.168.77.1
        ForwardAgent yes
      Host github.com
        Hostname ssh.github.com
        Port 443
    '';
  };
}
