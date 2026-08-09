# zaviro NixOS configuration

这是一个多主机 NixOS Flake，公开两个系统输出：

- `atlas`：日常使用的物理机，包含桌面、图形应用、容器和 Disko 布局声明。
- `legion-wsl`：通过 Tailscale/SSH 使用的轻量 WSL 环境。

系统配置位于 `hosts/`，可复用 NixOS 能力位于 `modules/nixos/`，可复用 Home
Manager 能力位于 `modules/home/`。每台主机通过自己的 `home.nix` 组合用户配置，
不暴露独立的 `homeConfigurations`。

仓库编辑完成后的验证、激活、提交和推送规则见
[`done-any-edit` skill](.agents/skills/done-any-edit/SKILL.md)。
