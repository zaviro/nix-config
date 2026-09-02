{ codexPackage, pkgs, ... }:

{
  home-manager.users.zaviro = {
    imports = [
      ../../modules/git.nix
      ../../modules/tmux.nix
    ];

    home = {
      username = "zaviro";
      homeDirectory = "/home/zaviro";
      stateVersion = "26.05";
      packages = [
        codexPackage
        pkgs.gh
        pkgs.jq
        pkgs.ripgrep
      ];
    };

    programs.home-manager.enable = true;

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };

        "github.com" = {
          HostName = "ssh.github.com";
          User = "git";
          Port = 443;
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
          AddKeysToAgent = "yes";
        };
      };
    };

    services.ssh-agent.enable = true;
  };
}
