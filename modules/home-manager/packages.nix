{ pkgs, ... }:

{
  # 所有主机都需要的用户级工具；系统启动所需软件应留在 NixOS 配置中。
  home.packages = with pkgs; [
    # Nix 与开发基础工具。
    nixfmt
    devenv

    # Agent、脚本和 Nixvim 都直接受益的非交互工具。
    ripgrep
    curl
    jq
    gh

    # 日常终端工作流。
    bat
    eza
    fd
    fzf
    htop
    zoxide
    direnv
    delta
    uv
    lazygit
  ];
}
