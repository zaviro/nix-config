# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概述

这是 zaviro 的 Nix 配置仓库，**仅在 Ubuntu 上通过 Home Manager 管理用户环境**（非 NixOS）。结构遵循 [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) 标准模板。

**全局软件安装统一使用 Home Manager**（`home-manager/default.nix` 的 `home.packages`），不使用 `nix profile` 或 `nix-env`。当用户说"安装 XX 到 home"时，意为通过 Home Manager 安装。

## 编辑配置后完整流程

详见 `.claude/rules/done-any-edit.md`。

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

## Conventional Commits

所有提交必须遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范。

### 格式

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### 类型 (type)

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档变更 |
| `style` | 代码格式（不影响逻辑的空格/缩进等） |
| `refactor` | 重构（既非 feat 也非 fix） |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/依赖/工具等杂务 |
| `ci` | CI/CD 配置 |
| `build` | 构建系统变更 |

### 规则

- `feat` 和 `fix` 会触发版本号变更（与 SemVer 联动），其余类型通常不计入
- scope 用圆括号包裹，如 `feat(home): ...`、`fix(nixvim): ...`
- scope 紧跟 type 冒号之后，如 `feat(tmux): add Nord theme`
- description 用英文，正文可用中文
- 破坏性变更在 type/scope 后加 `!`，如 `feat!: drop support for Node 16`
- 提交信息必须如实描述 diff 内容，不应包含未实际变更的功能

### 示例

```
feat(home): add tmux config with Nord theme
fix(nixvim): correct LSP server filetypes for ts_ls
docs: update CLAUDE.md with commit conventions
refactor: reorganize home-manager module structure
```
