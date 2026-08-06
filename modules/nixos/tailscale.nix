{ pkgs, ... }:

{
  # 两台 NixOS 主机都通过系统守护进程接入 tailnet，并启用 Tailscale SSH。
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--ssh" ];
  };

  environment.systemPackages = [ pkgs.tailscale ];
}
