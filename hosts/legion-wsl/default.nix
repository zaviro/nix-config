{
  codexPackage,
  home-manager,
  nixos-wsl,
  nixvim,
  pkgs,
  ...
}:

{
  imports = [
    nixos-wsl.nixosModules.default
    home-manager.nixosModules.home-manager
    ../../modules/nixos/common.nix
    ./tailscale.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # 接管同名普通文件时保留原件；若备份已存在，激活会显式失败。
    backupFileExtension = "hm-backup";

    extraSpecialArgs = { inherit nixvim; };

    users.zaviro = {
      imports = [ ../../home/zaviro ];

      # Codex 与 Tailscale 客户端目前仅在 WSL 使用，因此保留在主机覆盖层。
      home.packages = [
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
    };
  };

  networking.hostName = "legion-wsl";

  wsl = {
    enable = true;
    defaultUser = "zaviro";
  };

  # 该值来自本机首次安装，只约束有状态系统数据的兼容基线。
  system.stateVersion = "26.05";
}
