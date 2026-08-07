{
  # 机器级二进制缓存：TUNA 镜像、官方 fallback、Numtide(llm-agents)。
  # 在系统层声明 substituters 与签名密钥后，普通用户构建即可直接命中缓存。
  nix.settings.substituters = [
    # TUNA：nixpkgs / NixOS 官方产物国内镜像
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    # 官方 fallback
    "https://cache.nixos.org/"
    # Numtide：llm-agents（claude-code / codex）的构建产物
    "https://cache.numtide.com"
  ];

  nix.settings.trusted-public-keys = [
    # 官方缓存签名
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    # Numtide 缓存签名
    "numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];
}
