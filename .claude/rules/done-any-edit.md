# 编辑配置后的执行流程

## 常规检查

每次修改 Nix 配置后按以下顺序执行：

```bash
# 1. 格式化
nix fmt

# 2. 检查空白错误和 Flake 求值
git diff --check
nix flake check

# 3. 显式构建受影响的输出
nix build .#homeConfigurations.zaviro.activationPackage --no-link
nix build '.#homeConfigurations."zaviro@ubuntu".activationPackage' --no-link
```

新增文件必须先暂存，Git Flake 才会在求值时包含它们：

```bash
git add <new-files>
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

未来加入 NixOS 主机后，还必须显式构建对应系统输出，再依次执行
`nixos-rebuild test` 和 `nixos-rebuild switch`；具体命令应随主机接入一并补充。

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
