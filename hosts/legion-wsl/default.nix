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
    ../../modules/nixos/tailscale.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # 接管同名普通文件时保留原件；若备份已存在，激活会显式失败。
    backupFileExtension = "hm-backup";

    extraSpecialArgs = { inherit nixvim; };

    users.zaviro = {
      imports = [ ../../home/zaviro ];

      home.packages = [ codexPackage ];

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

  # WSL 磁盘空间较小：仅保留最近 5 个系统代际，再回收不再引用的 Store 内容。
  systemd.services.nix-gc-keep-generations = {
    description = "Keep the latest 5 NixOS system generations";

    serviceConfig.Type = "oneshot";

    script = ''
      ${pkgs.nix}/bin/nix-env \\
        --profile /nix/var/nix/profiles/system \\
        --delete-generations +5
      ${pkgs.nix}/bin/nix-collect-garbage
    '';
  };

  # 不补跑错过的清理，避免启动 WSL 后立即产生额外 I/O。
  systemd.timers.nix-gc-keep-generations = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "weekly";
  };

  wsl = {
    enable = true;
    defaultUser = "zaviro";
  };

  # 该值来自本机首次安装，只约束有状态系统数据的兼容基线。
  system.stateVersion = "26.05";
}
