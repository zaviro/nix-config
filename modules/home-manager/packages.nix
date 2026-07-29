{ pkgs, ... }:

{
  # 所有主机都需要的用户级工具；系统启动所需软件应留在 NixOS 配置中。
  home.packages = with pkgs; [
    nh
    nixfmt
    git
    devenv
  ];
}
