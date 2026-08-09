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

对于当前机器的低风险 NixOS 或 Home Manager 配置改动，在完成所需格式化、检查和构建后，自动执行 `nh os test ~/nix-config`，成功后立即执行 `nh os switch ~/nix-config`。不要使用 `sudo nh os`，也不要运行 `nh home switch`。纯文档、注释或格式修改不激活。

以下变更可能让机器无法正常使用或失去恢复通道，必须先报告风险并取得用户确认，不得自动激活：Disko、引导加载器、内核或 initrd、网络（包括 NetworkManager、Tailscale、SSH）、防火墙、认证或提权、显示管理器、桌面会话或图形栈。共享模块仍须遵守仓库的跨主机范围约束。

激活前先确认新的 `toplevel` 已实现，并记录当前系统 generation：

```bash
current_generation="$(readlink /nix/var/nix/profiles/system | sed -n 's/^system-\\([0-9]\\+\\)-link$/\\1/p')"
test -n "$current_generation"
```

`nh os test` 会真实激活配置，但不设为下次启动默认；`nh os switch` 会重新运行激活并持久化该配置。`switch` 成功退出即可视为成功，无需额外健康检查。若构建或激活前校验失败，系统未切换，绝不执行回滚。只有输出表明已开始激活而 `test` 或 `switch` 失败时，才执行：

```bash
nh os rollback --to "$current_generation"
```

回滚也失败时立即停止并向用户报告；不要尝试 Disko 或其他破坏性恢复操作。

WSL 仅在目标机器上按下列顺序执行：

```bash
nh os test ~/nix-config
nh os switch ~/nix-config
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

完成验证及所需的 `test`/`switch` 后，核对工作区与 diff，只暂存本次任务涉及的文件，并使用 Conventional Commit：

```bash
git status --short
git diff
git diff --cached
git commit -m "<type>(<scope>): <description>"
```

提交成功后自动推送到 `main`，不允许 force push。先确认当前分支为 `main`，获取远端状态，并审查待推送提交：

```bash
test "$(git branch --show-current)" = main
git fetch origin
git log --oneline origin/main..HEAD
```

若本地 `main` 落后或与 `origin/main` 分叉，运行 `git rebase origin/main`，并再次审查待推送提交。若 fetch 或 rebase 失败、发生 rebase 冲突、审查发现本次任务以外的既有提交，或 push 被拒绝，立即停止并请示用户。确认待推送内容仅包含本次任务后运行：

```bash
git push origin main
```
