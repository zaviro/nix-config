---
name: done-any-edit
description: Complete and safely hand off edits in this NixOS configuration repository. Use whenever modifying repository files, especially NixOS, Home Manager, flake inputs, host configuration, or documentation, to select validation, activation, commit, push, and cross-host safeguards.
---

# Done Any Edit

完成任何改动前后都遵循本工作流。新增文件先暂存，Git Flake 才能在求值时包含它们：

```bash
git add <new-files>
```

## 验证

纯文档、注释或格式修改只运行空白检查：

```bash
git diff --check
git diff --cached --check
```

修改 Nix 配置时，按以下顺序运行：

```bash
nix fmt
git diff --check
git diff --cached --check
nix flake check
```

按实际 diff 选择额外验证：

| 修改范围 | 必需验证 |
| --- | --- |
| `hosts/atlas/**` | atlas 求值和完整构建 |
| `hosts/legion-wsl/**` | legion-wsl 求值和完整构建 |
| `home/**`、`modules/home-manager/**` | 两个 NixOS 输出求值，当前 atlas 完整构建 |
| `modules/nixos/**` 或共享输入接线 | 两个 NixOS 输出求值，并分别完整构建 |

使用：

```bash
nix eval .#nixosConfigurations.legion-wsl.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.atlas.config.system.build.toplevel.drvPath
nix build .#nixosConfigurations.legion-wsl.config.system.build.toplevel --no-link
nix build .#nixosConfigurations.atlas.config.system.build.toplevel --no-link
```

完整构建后确认目标确实在 store 中：

```bash
system_toplevel="$(nix build .#nixosConfigurations.atlas.config.system.build.toplevel --no-link --print-out-paths)"
nix path-info "$system_toplevel"
```

如果当前机器无法承担另一台主机的构建，交由 CI、目标机器或具备缓存/远程 builder 的构建机完成。

## 激活

默认不得执行 `nh os test` 或 `nh os switch`。只有用户明确授权临时激活或持久激活时才可执行。不要使用 `sudo nh os`，也不要运行 `nh home switch`。

在授权的临时激活前，先确认新的 `toplevel` 已实现。若修改 `nixpkgs`、内核、systemd、NetworkManager、显示管理器、桌面会话或 Home Manager input，先运行：

```bash
nix store diff-closures /run/current-system "$system_toplevel"
```

报告风险并再次取得确认后才可临时激活。WSL 仅在目标机器上按下列顺序执行：

```bash
nh os test ~/nix-config
nh os switch ~/nix-config
```

atlas 的授权激活后检查：

```bash
systemctl --failed
systemctl is-active home-manager-zaviro.service
```

`nh` 不可用时，才使用恢复命令：

```bash
sudo nixos-rebuild switch --flake ~/nix-config
```

常规构建、`test` 与 `switch` 都不得执行 Disko 脚本。

## 跨主机与 SSH

默认只管理当前主机。不得远程写入、激活或 SSH 到另一台主机，除非用户明确要求跨机器操作。Tailscale SSH 的简短主机名是：

```bash
tailscale ssh zaviro@atlas
tailscale ssh zaviro@legion-wsl
```

仅在用户明确要求 SSH 访问另一台主机时使用这些命令；不得将其用于日常验证、构建、激活或未授权的跨机器操作。

## Flake lock

目录移动、模块拆分和普通配置修改不得改变 `flake.lock`。改变 input 拓扑（新增、删除、URL 或 `follows`）后必须运行 `nix flake lock`，但不得借此隐式升级依赖。只有用户明确要求更新、升级、最新版本或指定 revision 时，才可运行：

```bash
nix flake update <input-name>
nix flake update
```

更新依赖应独立提交，并完成所有受影响主机的必要验证。不要自动调整 `home.stateVersion` 或 `system.stateVersion`。

## 提交与推送

完成验证后，核对工作区与 diff，只暂存本次任务涉及的文件，并使用 Conventional Commit：

```bash
git status --short
git diff
git diff --cached
git commit -m "<type>(<scope>): <description>"
```

只有用户明确要求推送、发布或创建 PR 时才推送。先检查：

```bash
git status -sb
git log --oneline @{upstream}..HEAD
```

已有 upstream 时运行 `git push`；新分支使用 `git push -u origin "$(git branch --show-current)"`。不要使用 force push。
