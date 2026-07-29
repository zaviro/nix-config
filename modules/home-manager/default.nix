{ nixvim, ... }:

{
  # 此处只聚合跨主机共享的用户环境；身份和主机差异由上层模块负责。
  imports = [
    nixvim.homeModules.nixvim
    ./packages.nix
    ./nixvim.nix
    ./tmux.nix
  ];
}
