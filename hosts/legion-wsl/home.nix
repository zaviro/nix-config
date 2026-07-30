{ codexPackage, pkgs, ... }:

{
  # GitHub、Codex 与 Tailscale 客户端目前仅在 WSL 使用，因此保留在主机覆盖层。
  home.packages = [
    pkgs.gh
    codexPackage
    pkgs.tailscale
  ];
}
