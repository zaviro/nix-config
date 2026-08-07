{
  imports = [ ./cache.nix ];

  # 所有 NixOS 主机共享命令行与 Flake 支持。
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
