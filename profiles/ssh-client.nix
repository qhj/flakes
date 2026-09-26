{
  programs.ssh = {
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
