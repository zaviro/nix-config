# AGENTS.md

本文件说明仓库约束。具体编辑完成流程见
`.agents/skills/done-any-edit/SKILL.md`。

## 概述

这是 zaviro 的多主机 NixOS 配置仓库，提供
`nixosConfigurations."legion-wsl"` 和 `nixosConfigurations.atlas`。两个输出都
将 Home Manager 作为 NixOS module 接入，因此系统配置和用户配置会在同一次
NixOS 激活中生效。atlas 是日常使用的主力物理机，其磁盘布局由主机目录中的
Disko 声明记录。

用户级软件和偏好统一由 Home Manager 管理，不使用 `nix profile` 或
`nix-env`。NixOS 启动、服务和系统级依赖则由对应主机的 NixOS 模块管理。

## 主机操作范围

除非用户明确要求跨机器修改或验证，否则在任意机器上工作时只管理当前机器的
配置：只编辑该主机的专属配置，只求值和构建该主机对应的 Flake 输出，也只在
该主机执行激活。不得顺带修改、构建、激活或通过 SSH 操作其他机器。共享模块的
修改会影响多台机器，因此必须先取得用户对跨机器变更范围的明确要求。

## 架构

```text
flake.nix
├── home/
│   └── zaviro/
│       └── default.nix
├── hosts/
│   ├── atlas/
│   │   ├── default.nix
│   │   ├── disko.nix
│   │   └── hardware-configuration.nix
│   ├── legion-wsl/
│   │   ├── default.nix
│   │   └── tailscale.nix
├── modules/
│   ├── home-manager/
│   │   ├── packages.nix
│   │   ├── nixvim.nix
│   │   └── tmux.nix
│   └── nixos/
│       └── common.nix
├── overlays/
└── pkgs/
```

- `hosts/<hostname>/default.nix` 是每台主机唯一的配置组装入口。
- `hosts/atlas/default.nix` 组合物理机系统配置、嵌入式 Home Manager 与共享
  用户配置；同目录的 Disko 和硬件文件只服务 atlas。
- `hosts/legion-wsl/default.nix` 组合 WSL 平台、系统配置、嵌入式 Home
  Manager、共享用户配置及 WSL 特有的用户级覆盖。
- `home/zaviro/default.nix` 是 zaviro 的跨主机 Home Manager 共享配置模块，
  声明用户身份、Home Manager 状态版本并组合共享功能模块。
- `modules/home-manager/` 保存不写死用户名和主机名的可复用用户级功能模块，
  由共享用户配置模块按需组合。
- `modules/nixos/` 只保存多台 NixOS 主机实际共享的系统模块；主机专属系统
  配置保留在对应的 `hosts/<hostname>/default.nix`。
- `overlays/` 和 `pkgs/` 仍是占位结构，尚未接入有效输出。

`flake.nix` 只负责依赖、输出、启动模块系统和依赖注入，不直接选择或组合具体
配置。它通过 `specialArgs` / `extraSpecialArgs` 向主机入口提供实际依赖。
`home/zaviro/default.nix` 会导入 Nixvim 的 Home Manager module；两台 NixOS
主机将其转交给内层 Home Manager 模块系统。legion-wsl 和 atlas 单独接收 Codex
包，避免主机覆盖依赖完整的 Flake inputs。

两台主机统一使用根 `nixpkgs` 输入（`nixos-unstable`），具体版本由 `flake.lock`
固定。Disko 自身固定在安装时验证过的 revision，并跟随根软件集。共享 Home
Manager 与 Nixvim 也跟随根输入，因此更新共享用户模块时两台主机都需要求值验证。

## 常用命令

```bash
# 通用检查
nix fmt
nix flake check

# atlas
nix build .#nixosConfigurations.atlas.config.system.build.toplevel --no-link
# 低风险配置改动完成构建后自动依次运行
nh os test ~/nix-config
nh os switch ~/nix-config

# legion-wsl
nix build .#nixosConfigurations.legion-wsl.config.system.build.toplevel --no-link
# 低风险配置改动完成构建后自动依次运行
nh os test ~/nix-config
nh os switch ~/nix-config
```

两台机器都以普通用户运行 `nh os`。它会在系统激活阶段自动调用可用的提权工具，
不得使用 `sudo nh os`。Home Manager 已嵌入系统，也不得单独运行
`nh home switch`。对于当前机器的低风险配置改动，完成格式化、检查和必要构建后，
自动依次运行 `nh os test` 与 `nh os switch`；前者真实激活但不设为下次启动默认，
后者持久激活。纯文档、注释或格式修改无需激活。Disko、引导加载器、内核或
initrd、网络或远程访问、防火墙、认证或提权、显示管理器或图形会话等可能使机器
无法正常使用或失去恢复通道的变更，必须先报告风险并取得用户确认。

运行 `test` 前须记录当前系统 generation。若构建或激活前校验失败，不得回滚；
若已进入激活且 `test` 或 `switch` 失败，则使用 `nh os rollback --to <记录的 generation>`
恢复。`switch` 成功退出即视为持久激活成功，不重复执行额外健康检查。

`nh os` 默认按本机 hostname 选择对应的 `nixosConfigurations` 输出。
`home-manager-zaviro.service` 是系统级服务，检查激活结果时不要使用
`systemctl --user`。仅当 `nh` 不可用时，NixOS 主机才使用原生恢复命令：

```bash
sudo nixos-rebuild switch --flake ~/nix-config
```

普通 `nixos-rebuild` / `nh os` 不会执行 Disko 或重新格式化磁盘。Disko 配置
用于描述 atlas 的既有布局；除非是经过单独核对和确认的重装或恢复任务，不得
执行 Disko 生成的脚本。

更改 input 拓扑（新增、删除、URL 或 `follows` 关系）后，必须运行
`nix flake lock`，使 `flake.lock` 与 `flake.nix` 同步；该命令不得用于隐式升级
已有依赖。只有任务明确要求更新、升级、最新版本或指定 revision 时，才运行
`nix flake update <input-name>` 或 `nix flake lock --update-input <input-name>`。
依赖升级必须独立提交并完成必要验证。`nixos-unstable` 是输入分支，实际使用的
提交始终以 `flake.lock` 为准，不会随构建自动更新。目录移动、模块拆分和普通
配置修改不得顺带更新依赖。

## 代码风格

- Nix 变量、选项和路径使用英文。
- 注释使用中文，解释模块职责、约束原因和非显然行为。
- 不给自解释配置添加逐行复述式注释。
- 使用 flake 暴露的 `nixfmt` 执行格式化。
- `home.stateVersion` 和 `system.stateVersion` 不随依赖更新自动修改。

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

任何改动成功完成并通过必要检查后，都必须创建本地提交。提交前应核对工作区，
仅暂存本次任务涉及的文件，不得把用户已有或无关的改动带入提交。

提交后自动推送到 `main`，且绝不 force push。先运行 `git fetch origin` 并检查本地
`main` 与 `origin/main`；如本地落后或分叉，运行 `git rebase origin/main`，再运行
`git push origin main`。fetch 或 rebase 失败、出现 rebase 冲突、发现待推送内容包含
本次任务以外的既有提交，或 push 被拒绝时，立即停止并请示用户。
