{ nixvim, ... }:

{
  # 组合 zaviro 在各主机间共享的 Home Manager 配置。
  imports = [
    nixvim.homeModules.nixvim
    ../../modules/home-manager/packages.nix
    ../../modules/home-manager/nixvim.nix
    ../../modules/home-manager/tmux.nix
  ];

  # 用户身份只在个人入口声明，共享模块不得写死用户名或 home 路径。
  home = {
    username = "zaviro";
    homeDirectory = "/home/zaviro";
    # 该值约束有状态数据的兼容基线，升级 Home Manager 时也不要随意修改。
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
