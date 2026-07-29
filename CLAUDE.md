# CLAUDE.md

本文件说明仓库约束。具体编辑完成流程见
`.claude/rules/done-any-edit.md`。

## 概述

这是 zaviro 的多主机 Nix 配置仓库。

当前已接入 Ubuntu 的 standalone Home Manager，提供两个等价输出：

- `homeConfigurations.zaviro`：迁移期兼容键。
- `homeConfigurations."zaviro@ubuntu"`：与真实 hostname 对应的主机限定键。

NixOS-WSL 主机 `legion-wsl` 将在后续独立提交中接入。在该提交完成前，
仓库没有 `nixosConfigurations` 输出。

用户级软件和偏好统一由 Home Manager 管理，不使用 `nix profile` 或
`nix-env`。NixOS 启动、服务和系统级依赖则由对应主机的 NixOS 模块管理。

## 架构

```text
flake.nix
├── home/
│   └── zaviro/
│       └── default.nix
├── hosts/
│   └── ubuntu/
│       └── home.nix
├── modules/
│   ├── home-manager/
│   │   ├── default.nix
│   │   ├── packages.nix
│   │   ├── nixvim.nix
│   │   └── tmux.nix
│   └── nixos/
│       └── default.nix
├── overlays/
└── pkgs/
```

- `home/zaviro/default.nix` 只声明用户身份、Home Manager 状态版本和共享模块入口。
- `hosts/ubuntu/home.nix` 只保存 Ubuntu 特有的用户级覆盖。
- `modules/home-manager/` 保存不写死用户名和主机名的跨主机模块。
- `modules/nixos/`、`overlays/` 和 `pkgs/` 目前仍是占位结构，尚未接入有效输出。

`modules/home-manager/default.nix` 会导入 Nixvim 的 Home Manager module，
因此所有组合入口都必须通过 `extraSpecialArgs` 提供 `nixvim`。未来在 NixOS
中嵌入 Home Manager 时，应设置：

```nix
home-manager.extraSpecialArgs = { inherit nixvim; };
```

## 常用命令

```bash
nix fmt
nix flake check
nix build .#homeConfigurations.zaviro.activationPackage --no-link
nix build '.#homeConfigurations."zaviro@ubuntu".activationPackage' --no-link
nh home build ~/nix-config
nh home switch ~/nix-config
```

只有新增、删除或主动更新 flake input 时才允许修改 `flake.lock`。目录移动、
模块拆分和普通配置修改不得顺带更新依赖。

## 代码风格

- Nix 变量、选项和路径使用英文。
- 注释使用中文，解释模块职责、约束原因和非显然行为。
- 不给自解释配置添加逐行复述式注释。
- 使用 flake 暴露的 `nixfmt` 执行格式化。
- `home.stateVersion` 和未来的 `system.stateVersion` 不随依赖更新自动修改。

## 安全约束

- 不得向仓库提交 API key、密码、私钥或其他明文凭证。
- `secrets/` 只能在选定 sops-nix 或 agenix 等方案后创建。
- 即使采用密钥管理工具，仓库中也只能保存加密材料和公开元数据。

## Conventional Commits

提交格式：

```text
<type>[optional scope]: <description>
```

常用类型：

| 类型 | 用途 |
| --- | --- |
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档变更 |
| `refactor` | 不改变行为的结构调整 |
| `test` | 测试与验证 |
| `build` | 依赖或构建系统 |
| `chore` | 其他维护工作 |

description 使用英文，并确保每个提交只描述其实际 diff。
