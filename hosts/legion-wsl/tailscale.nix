{
  # Tailscale 需要系统守护进程创建网络接口，不能仅由 Home Manager 启动。
  services.tailscale = {
    enable = true;
    # 通过 Tailscale 守护进程提供 SSH，不额外暴露传统 SSH 端口。
    extraSetFlags = [ "--ssh" ];
  };
}
