{ inputs, pkgs, ... }:

{
  imports = [ ../../modules/nixos/common.nix ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # 接管同名普通文件时保留原件；若备份已存在，激活会显式失败。
    backupFileExtension = "hm-backup";

    # 只向用户模块暴露实际依赖，避免主机覆盖直接依赖完整 inputs 集合。
    extraSpecialArgs = {
      codexPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
      nixvim = inputs.nixvim;
    };

    users.zaviro.imports = [
      ../../home/zaviro
      ./home.nix
    ];
  };

  networking.hostName = "legion-wsl";

  wsl = {
    enable = true;
    defaultUser = "zaviro";
  };

  # 该值来自本机首次安装，只约束有状态系统数据的兼容基线。
  system.stateVersion = "26.05";
}
