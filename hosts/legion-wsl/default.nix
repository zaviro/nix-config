{ inputs, pkgs, ... }:

{
  imports = [ ../../modules/nixos/common.nix ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # 首次接管同名普通文件时先保留原件，不做静默覆盖。
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      nixvim = inputs.nixvim;
    };

    users.zaviro.imports = [
      ../../home/zaviro
      ./home.nix
    ];
  };

  # 首次激活期间暂时保留当前系统级工具，验证后再整理软件归属。
  environment.systemPackages = [
    pkgs.git
    pkgs.gh
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
  ];

  networking.hostName = "legion-wsl";

  wsl = {
    enable = true;
    defaultUser = "zaviro";
  };

  # 该值来自本机首次安装，只约束有状态系统数据的兼容基线。
  system.stateVersion = "26.05";
}
