{
  # Tailscale 需要系统守护进程创建网络接口，不能仅由 Home Manager 启动。
  services.tailscale.enable = true;
}
