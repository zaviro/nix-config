# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概述

这是 zaviro 的 Nix 配置仓库，**仅在 Ubuntu 上通过 Home Manager 管理用户环境**（非 NixOS）。结构遵循 [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) 标准模板。

## 编辑配置后完整流程

每次修改 Nix 配置后按此顺序执行（详见 `.claude/rules/done-any-edit.md`）：

```bash
nix fmt                                    # 1. 格式化
nix flake check                            # 2. 前置校验（语法/引用）
nix flake update                           # 3. 更新 flake.lock（或 nix flake lock --update-input <name>）
nix flake check                            # 4. 更新后再次校验
nh home build ~/nix-config         # 5. 预构建测试（只构建不激活）
nh home switch ~/nix-config        # 6. 正式激活切换
# 7. 验证配置修改后系统行为符合预期
git add . && git commit -m "..."           # 8. 统一提交（含 flake.lock）
```

## 其他常用命令

```bash
nh home switch ~/nix-config   # 快速应用（无依赖变更时）
nix flake show                         # 查看 flake 所有输出
nix flake lock --update-input <name>   # 仅更新指定依赖
```

**注意**：`hosts/ubuntu/configuration.nix` 是占位 NixOS 配置，当前未使用。如需 NixOS 重建需先生成 `hardware-configuration.nix`。

## 架构

```
flake.nix              # 入口：3 个输入 (nixpkgs, home-manager, nixvim)
├── home-manager/      # ★ 活跃配置：zaviro 用户环境
│   └── default.nix    # zsh, tmux, nixvim(neovim), 环境变量, 别名
├── hosts/ubuntu/      # NixOS 系统配置（占位，未激活）
├── overlays/          # 3 个 overlay: additions, modifications, unstable-packages
├── pkgs/              # 自定义包（空占位）
└── modules/           # 可复用模块（空占位）
```

- **home-manager/default.nix** 是核心文件，管理 zsh（Oh My Zsh + 原生插件）、tmux（Nord 主题 + Claude Code 透传）、nixvim（LSP/treesitter/telescope/Catppuccin Mocha 主题）
- `home-manager` 和 `nixvim` 的 nixpkgs 均通过 `follows` 跟随主 nixpkgs，保证版本一致
- `extraSpecialArgs` 向子模块传递 `nixvim`

## 代码风格

- 变量名和 Nix 语法使用英文，注释使用中文
- 格式化工具为 nixfmt（通过 `nix fmt` 调用 flake formatter 输出）
- 缩进：2 空格
- zsh initContent 中包含 API keys（OpenRouter、Tavily）—— 修改时注意不要泄露到公开仓库
