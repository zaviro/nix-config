{
  # 订阅配置含敏感信息，运行时通过 systemd credential 从仓库外读取，不能加入 Git 或 Nix store。
  services.mihomo = {
    enable = true;
    configFile = "/home/zaviro/clash/config.yaml";

    # 首次部署不授予 TUN 权限，确认本机代理可用后再单独启用透明代理。
    tunMode = false;
  };
}
