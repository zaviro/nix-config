{
  # 订阅配置含敏感信息，运行时通过 systemd credential 从仓库外读取，不能加入 Git 或 Nix store。
  services.mihomo = {
    enable = true;
    configFile = "/home/zaviro/clash/config.yaml";

    # TUN 模式需要 systemd 服务访问虚拟网卡并管理自动路由。
    tunMode = true;
  };
}
