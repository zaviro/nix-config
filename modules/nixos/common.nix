{
  # 所有 NixOS 主机共享命令行与 Flake 支持。
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # llm-agents 的二进制缓存避免在本机重复构建大型依赖。
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
