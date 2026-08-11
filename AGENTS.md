# AGENTS.md

本仓库维护 zaviro 的两台 NixOS 主机：`atlas`（日常使用的物理机）和
`legion-wsl`（远程/WSL 环境）。两者都把 Home Manager 嵌入 NixOS，因此一次系统
激活同时更新系统和用户配置。公开 Flake 接口只包含
`nixosConfigurations.atlas` 与 `nixosConfigurations.legion-wsl`。

## 结构语义

- `hosts/<host>/default.nix` 是主机系统的 composition root。
- `hosts/<host>/home.nix` 是该主机的 Home Manager composition root，声明用户身份、
  主机选择和主机专属包。
- `modules/nixos/` 与 `modules/home/` 是可复用能力；`bundles/` 只表达稳定意图，
  只导入同层静态模块，不嵌套 bundle。
- 主机实例直接导入单一 module；共同变更原因才拆为主机 fragment。
- 依赖方向为 `host -> bundle -> module`；module 不反向导入 host。
- `flake.nix` 只负责 inputs、输出和依赖注入，不组合具体主机功能。

## 放置决策

| 内容 | 位置 |
| --- | --- |
| 系统能力 | `modules/nixos/` |
| 用户能力 | `modules/home/` |
| 稳定能力集合 | 对应目录的 `bundles/` |
| 主机策略/硬件/磁盘 | `hosts/<host>/` |
| 主机用户选择与身份 | `hosts/<host>/home.nix` |

每个用户 CLI 只能由 `home.packages` 或对应的 `programs.<name>.enable` 之一提供；
启用后者前须确认它是否已自动安装该包。

工具能力的临时使用、添加、替换和移除流程见
[`provision-nix-capability` skill](.agents/skills/provision-nix-capability/SKILL.md)。

## 版本控制

本仓库使用 colocated Jujutsu/Git workspace：Jujutsu 管理工作区、历史与远端写操作，
Git 仅作为存储后端和只读兼容层。远端只保留长期 `main` bookmark；本地工作位于
`main` 之上的匿名 changes。完成验证和激活不代表发布：只有用户明确要求发布或推送
`main` 时，才可把它前移并发布。需要远端备份、跨机器继续或 agent 交接时，使用短期、
按任务命名的 bookmark（如 `agent/<task>`）或 `push-*`；不得建立或共享长期 `next`
开发线。不得使用 Git 命令修改工作区、历史、refs 或远端状态。

除非用户明确要求跨机器，否则只编辑、求值、构建和激活当前主机；共享模块变更
需要明确接受其跨主机影响。不得提交明文凭证，`home.stateVersion` 与
`system.stateVersion` 保持 `26.05`。目录重构不得更新 `flake.lock`；只有 input
拓扑变化才运行 `nix flake lock`，依赖升级必须单独完成和验证。

编辑完成后的格式化、验证、风险激活、回滚、提交和推送流程统一见
[`.agents/skills/done-any-edit/SKILL.md](.agents/skills/done-any-edit/SKILL.md)。
