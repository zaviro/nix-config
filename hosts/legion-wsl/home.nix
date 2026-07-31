{ codexPackage, pkgs, ... }:

{
  # GitHub、Codex 与 Tailscale 客户端目前仅在 WSL 使用，因此保留在主机覆盖层。
  home.packages = [
    pkgs.gh
    codexPackage
    pkgs.tailscale
  ];

  programs.ssh = {
    enable = true;

    settings."github.com" = {
      HostName = "ssh.github.com";
      User = "git";
      Port = 443;
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
      AddKeysToAgent = "yes";
    };
  };

  services.ssh-agent.enable = true;
}
