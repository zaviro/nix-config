# 编辑配置后的执行流程

## 常规检查

新增文件必须先暂存，Git Flake 才会在后续求值时包含它们：

```bash
git add <new-files>
```

随后按以下顺序检查 Nix 配置：

```bash
# 1. 格式化
nix fmt

# 2. 检查空白错误和 Flake 求值
git diff --check
git diff --cached --check
nix flake check

# 3. 显式求值受影响的配置；共享模块变更应覆盖所有相关配置
nix eval '.#homeConfigurations."zaviro@ubuntu".activationPackage.drvPath'
nix eval .#nixosConfigurations.legion-wsl.config.system.build.toplevel.drvPath
```

随后完整构建当前主机的输出。Ubuntu 使用：

```bash
nix build '.#homeConfigurations."zaviro@ubuntu".activationPackage' --no-link
```

legion-wsl 使用：

```bash
nix build .#nixosConfigurations.legion-wsl.config.system.build.toplevel --no-link
```

其他主机的输出不要求在当前机器完整构建，应由 CI、目标机器或已配置对应
二进制缓存或远程 builder 的构建机完成。新增或更新 flake input、修改共享
基础设施等高风险变更，要求所有受影响主机最终各完成一次完整构建。

完成构建后检查实际 diff、同步架构文档，并只暂存本次提交需要的文件：

```bash
git status --short
git diff
git diff --cached
```

只有阶段性节点才执行激活。Ubuntu 使用：

```bash
nh home build ~/nix-config
nh home switch ~/nix-config
```

WSL 的阶段性激活按风险从低到高执行：

```bash
nh os build ~/nix-config
nh os test ~/nix-config
nh os switch ~/nix-config
```

Ubuntu 和 WSL 都以普通用户运行 `nh`，不得使用 `sudo nh`。`nh os` 会在
激活阶段自动提权，并按当前 hostname 选择
`nixosConfigurations.legion-wsl`。嵌入式 Home Manager 的激活结果通过
系统级 `home-manager-zaviro.service` 检查，不使用 `systemctl --user`。
WSL 不得运行 `nh home switch`，因为 standalone Home 输出属于 Ubuntu。

仅当 `nh` 不可用时，WSL 才使用原生恢复命令：

```bash
sudo nixos-rebuild switch --flake ~/nix-config
```

## 跨机器验证

两台主机位于同一 tailnet，当前 Tailscale 地址与 Tailscale SSH 状态如下：

| 主机 | Tailscale IPv4 | Tailscale SSH | 状态 |
| --- | --- | --- | --- |
| Ubuntu | `100.65.7.4` | `ssh zaviro@100.65.7.4` | `RunSSH = false`，当前不能作为 Tailscale SSH 目标 |
| legion-wsl | `100.109.1.84` | `ssh zaviro@100.109.1.84` | `RunSSH = true`，已验证可用 |

在 Ubuntu 完成配置编辑并推送后，可通过 legion-wsl 的 Tailscale SSH 入口测试
跨机器拉取、构建和激活。远端写入前先确认仓库干净，并只允许快进拉取：

```bash
ssh zaviro@100.109.1.84
git -C ~/nix-config status -sb
git -C ~/nix-config pull --ff-only
nh os build ~/nix-config
nh os test ~/nix-config
nh os switch ~/nix-config
systemctl is-active home-manager-zaviro.service
```

Ubuntu 的地址用于记录反向验证目标，但在单独启用并验证 Tailscale SSH 前不得
将其视为可用入口。Tailscale SSH 仅可从获准的 tailnet 客户端访问，并仍受
tailnet SSH 策略约束。

## Lock 文件策略

目录移动、模块拆分和普通选项修改不得改变 `flake.lock`。提交前应确认：

```bash
git diff -- flake.lock
```

只有明确新增或更新 input 时才运行：

```bash
# 更新指定 input
nix flake update <input-name>

# 仅在明确需要全量升级时更新全部 inputs
nix flake update
```

依赖变更必须形成独立、可回退的提交，并在 lock 更新后重新执行完整检查。
所有受影响主机还必须通过 CI、目标机器或具备对应缓存或远程 builder 的构建机
各完成一次完整构建。不得把全量依赖漂移混入结构重构或主机迁移。

## 提交

所有检查通过后，按实际范围使用 Conventional Commits：

```bash
git commit -m "<type>(<scope>): <description>"
```

## 推送

提交后先确认工作区状态，并检查将要推送的提交：

```bash
git status -sb
git log --oneline @{upstream}..HEAD
```

已有 upstream 的分支直接推送：

```bash
git push
```

新分支首次推送时显式设置 upstream：

```bash
git push -u origin "$(git branch --show-current)"
```

推送完成后再次运行 `git status -sb`，确认当前分支已与 upstream 同步。默认
不得使用 `--force` 或 `--force-with-lease`；若远端拒绝推送，应先检查远端新增
提交并解决分歧，不得绕过保护直接覆盖。
