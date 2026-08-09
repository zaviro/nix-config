{ pkgs, ... }:

{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC8qsJvpWm2Ha0KnW5tvT7eIqG2hOa4+gmJgJVXfewP/ wsl-nixos"
    ];
    zaviro = {
      isNormalUser = true;
      uid = 1000;
      shell = pkgs.zsh;
      extraGroups = [
        "docker"
        "wheel"
        "networkmanager"
        "video"
        "render"
        "audio"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC8qsJvpWm2Ha0KnW5tvT7eIqG2hOa4+gmJgJVXfewP/ wsl-nixos"
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;
}
