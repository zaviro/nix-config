# zaviro NixOS configuration

个人多主机 NixOS 配置，使用 Flake，并将 Home Manager 嵌入 NixOS。

## 主机

- `atlas`：日常使用的物理机。
- `legion-wsl`：通过 Tailscale/SSH 使用的 WSL 环境。

## 仓库结构

- `hosts/`：主机组合与主机专属策略。
- `modules/`：按功能组织的可复用配置。
- `bundles/`：供主机选择的稳定角色组合。

公开 Flake 接口包括 `nixosConfigurations.atlas`、
`nixosConfigurations.legion-wsl`、`rescue-iso` 和 `window-keybindings`。
