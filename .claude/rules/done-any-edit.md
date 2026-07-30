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

# 3. 显式构建受影响的输出；跨主机模块变更应构建全部输出
nix build '.#homeConfigurations."zaviro@ubuntu".activationPackage' --no-link
nix build .#nixosConfigurations.legion-wsl.config.system.build.toplevel --no-link
```

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

依赖变更必须形成独立、可回退的提交，并在 lock 更新后重新执行完整检查和构建。
不得把全量依赖漂移混入结构重构或主机迁移。

## 提交

所有检查通过后，按实际范围使用 Conventional Commits：

```bash
git commit -m "<type>(<scope>): <description>"
```
