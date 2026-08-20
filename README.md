# zaviro NixOS configuration

这是一个多主机 NixOS Flake，公开两个系统输出：

- `atlas`：日常使用的物理机，包含桌面、图形应用、容器和 Disko 布局声明。
- `legion-wsl`：通过 Tailscale/SSH 使用的轻量 WSL 环境。

系统配置位于 `hosts/`，可复用 NixOS 能力位于 `modules/nixos/`，可复用 Home
Manager 能力位于 `modules/home/`。每台主机通过自己的 `home.nix` 组合用户配置，
不暴露独立的 `homeConfigurations`。
`atlas` 每天检查一次自动更新状态；距上次成功检查满 7 天时，会在本地 JJ 历史中
创建独立的 `flake.lock` 更新 change，完成 Flake 检查和整机 build 后再 switch。
完整运行日志写入 `/var/log/nixos-flake-update/update.log`，失败不会刷新成功时间。
