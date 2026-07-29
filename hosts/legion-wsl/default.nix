{ inputs, pkgs, ... }:

{
  imports = [ ../../modules/nixos/common.nix ];

  # Home Manager 接入前先原样保留当前系统级工具，确保迁移过程可恢复。
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
