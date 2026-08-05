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
nix eval .#nixosConfigurations.atlas.config.system.build.toplevel.drvPath
```

随后完整构建当前主机的输出。Ubuntu 使用：

```bash
nix build '.#homeConfigurations."zaviro@ubuntu".activationPackage' --no-link
```

legion-wsl 使用：

```bash
nix build .#nixosConfigurations.legion-wsl.config.system.build.toplevel --no-link
```

atlas 使用：

```bash
nix build .#nixosConfigurations.atlas.config.system.build.toplevel --no-link
```

如果当前机器无法承担其他主机的完整构建，应由 CI、目标机器或已配置对应
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

atlas 使用同样的风险顺序：

```bash
nh os build ~/nix-config
nh os test ~/nix-config
nh os switch ~/nix-config
```

三台主机都以普通用户运行 `nh`，不得使用 `sudo nh`。`nh os` 会在激活阶段
自动提权，并按当前 hostname 选择对应的 `nixosConfigurations` 输出。嵌入式
Home Manager 的激活结果通过系统级 `home-manager-zaviro.service` 检查，不使用
`systemctl --user`。NixOS 主机不得运行 `nh home switch`，因为 standalone
Home 输出属于 Ubuntu。

仅当 `nh` 不可用时，NixOS 主机才使用原生恢复命令：

```bash
sudo nixos-rebuild switch --flake ~/nix-config
```

普通构建、`test` 和 `switch` 都不会执行 atlas 的 Disko 脚本。不得把 Disko
脚本执行加入日常激活流程；格式化仍需单独核对磁盘并取得明确确认。

## 跨机器验证

Ubuntu 与 legion-wsl 位于同一 tailnet；atlas 当前只确认了局域网 SSH，尚未
配置 Tailscale：

| 主机 | 已验证地址 | SSH 入口 | 状态 |
| --- | --- | --- | --- |
| Ubuntu | `100.65.7.4` | `ssh zaviro@100.65.7.4` | `RunSSH = false`，当前不能作为 Tailscale SSH 目标 |
| legion-wsl | `100.109.1.84` | `ssh zaviro@100.109.1.84` | Tailscale SSH 已验证可用 |
| atlas | `192.168.0.100` | `ssh zaviro@192.168.0.100` | 路由器静态 DHCP 分配，公钥 SSH 已验证可用 |

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

atlas 初次迁移可由 WSL 本地构建并通过 SSH 复制闭包，不要求 atlas 直接访问
GitHub。临时网络隧道不得写成永久系统代理；停止隧道前应确保目标主机没有依赖
对应 loopback 端口的持久配置。

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
