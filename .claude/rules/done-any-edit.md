# 编辑后的执行流程

## 常规检查

新增文件必须先暂存，Git Flake 才会在后续求值时包含它们：

```bash
git add <new-files>
```

纯文档修改只需执行空白检查。Nix 配置发生变化时，按以下顺序检查：

```bash
# 1. 格式化
nix fmt

# 2. 检查空白错误和 Flake 求值
git diff --check
git diff --cached --check
nix flake check

# 3. 显式求值受影响的配置；共享模块变更应覆盖所有相关配置
nix eval .#nixosConfigurations.legion-wsl.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.atlas.config.system.build.toplevel.drvPath
```

验证范围根据实际 diff 确定：

| 修改范围 | 必需验证 |
| --- | --- |
| `hosts/atlas/**` | atlas 求值和完整构建 |
| `hosts/legion-wsl/**` | legion-wsl 求值和完整构建 |
| `home/**`、`modules/home-manager/**` | 两个 NixOS 输出求值，当前 atlas 完整构建 |
| `modules/nixos/**` 或共享输入接线 | 两个 NixOS 输出求值，并最终分别完整构建 |
| 纯文档、注释或格式调整 | 空白检查；无需 Nix 求值、构建或激活 |

legion-wsl 的完整构建命令：

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

默认不得执行 `nh os test`。它会立即临时激活新配置，可能中断网络、图形会话、
服务或正在运行的任务；只有用户明确要求运行时测试或授权临时激活时才能运行。
若获得授权，WSL 的阶段性激活按风险从低到高执行，并且只能在目标机器运行：

```bash
nh os test ~/nix-config
nh os switch ~/nix-config
```

若用户明确授权 atlas 临时激活，先执行并检查结果：

```bash
nh os test ~/nix-config
systemctl --failed
systemctl is-active home-manager-zaviro.service
```

临时激活检查通过且本次任务明确要求持久激活时再执行：

```bash
nh os switch ~/nix-config
```

两台主机都以普通用户运行 `nh`，不得使用 `sudo nh`。`nh os` 会在激活阶段
自动提权，并按当前 hostname 选择对应的 `nixosConfigurations` 输出。嵌入式
Home Manager 的激活结果通过系统级 `home-manager-zaviro.service` 检查，不使用
`systemctl --user`。NixOS 主机不得运行 `nh home switch`。纯文档、注释或格式
修改不需要执行 `nh os test` 或 `nh os switch`。

仅当 `nh` 不可用时，NixOS 主机才使用原生恢复命令：

```bash
sudo nixos-rebuild switch --flake ~/nix-config
```

普通构建、`test` 和 `switch` 都不会执行 atlas 的 Disko 脚本。不得把 Disko
脚本执行加入日常激活流程；格式化仍需单独核对磁盘并取得明确确认。

## 跨机器验证

默认只管理当前 atlas。legion-wsl 专属修改可以在 atlas 求值或构建对应输出，
但不得从 atlas 远程写入或激活 legion-wsl，除非用户明确要求跨机器操作。共享
模块变更最终应由目标机器、CI 或已配置对应缓存或远程 builder 的构建机完成各自
的完整构建。

## Lock 文件策略

目录移动、模块拆分和普通选项修改不得改变 `flake.lock`。更改 input 拓扑
（新增、删除、URL 或 `follows` 关系）后，必须运行 `nix flake lock`，使锁文件
与 `flake.nix` 同步；不得借此隐式升级已有依赖。提交前应确认：

```bash
git diff -- flake.lock
```

只有任务明确要求更新、升级、最新版本或指定 revision 时，才运行：

```bash
# 更新指定 input
nix flake update <input-name>

# 仅在明确需要全量升级时更新全部 inputs
nix flake update
```

`nixos-unstable` 是输入分支，实际使用的提交始终以 `flake.lock` 为准，不会随
构建自动更新。依赖升级必须形成独立、可回退的提交，并在 lock 更新后重新执行
完整检查。所有受影响主机还必须通过 CI、目标机器或具备对应缓存或远程 builder
的构建机各完成一次完整构建。不得把全量依赖漂移混入结构重构或主机迁移。

## 提交

所有检查通过后，按实际范围使用 Conventional Commits：

```bash
git commit -m "<type>(<scope>): <description>"
```

## 推送

只有用户明确要求推送、发布或创建 PR 时才执行本节。提交后先确认工作区状态，
并检查将要推送的提交：

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
