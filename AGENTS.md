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

持久提供给普通用户的 CLI 只能有一个声明 owner，默认在 `home.packages` 与对应的
`programs.<name>.enable` 中二选一；启用后者前须确认它是否已自动安装该包。只有
NixOS 核心命令、系统服务客户端、登录 shell 等确有系统级语义时才使用系统级例外，
并在交付中说明。

工具能力的临时使用、添加、替换和移除流程见
[`provision-nix-capability` skill](.agents/skills/provision-nix-capability/SKILL.md)。

## 版本控制政策

本仓库使用 colocated Jujutsu/Git workspace。Jujutsu 管理工作区、历史、bookmark 与
远端写操作；Git 仅作为存储后端和只读兼容层，不得用 Git 修改工作区、index、历史、
refs 或远端状态。

远端只保留长期 `main` bookmark；本地工作默认位于 `main` 之上的匿名 changes。
完成、验证和激活都不构成发布授权；只有用户明确要求发布或推送 `main` 时，才可前移
并推送它。远端备份、跨机器继续或 agent 交接可以使用按任务命名的短期 bookmark 或
`push-*`，但不得建立长期 `next` 开发线。

change 边界按可独立审阅、验证、保留和回滚的语义单元划分，不按用户消息、对话回合、
验证阶段或工具批次划分。简单而连贯的请求默认保持一个 change；保留已有边界，不得
混入、重写、丢弃或撤销来源不明、属于用户或其他操作者的工作。

默认使用当前 workspace；只有并行隔离或长时间测试确有价值时才建立额外 workspace。
workspace 不自动授权创建 bookmark、访问远端或发布。首次编辑仓库文件（包括准备纳入
仓库的新文件）前，以及执行任何状态检查、change 整理、冲突、恢复、bookmark、远端或
workspace 操作时，必须
使用 [`$jj-guide` skill](.agents/skills/jj-guide/SKILL.md)。它负责 Jujutsu 的具体命令与
安全检查，但不能扩大本文件规定的权限。

默认目标是当前主机。只有用户明确指定另一主机时，才编辑或完整构建它的主机专属
配置；修改共享源必须由请求本身涵盖或由用户明确接受其跨主机影响。在当前机器上对
另一公开 `nixosConfiguration` 做不改变机器状态的本地求值，可以作为共享变更的兼容性
检查，不算跨机器操作；它不授权 SSH、写入或激活另一机器。不得提交明文凭证，
`home.stateVersion` 与 `system.stateVersion` 保持 `26.05`。目录重构不得更新
`flake.lock`；input 拓扑变化只授权重建与新拓扑一致的 lock graph，只有用户明确要求
依赖升级时才可更新已锁定 input 的版本。依赖升级必须作为独立意图完成和验证。

修改过仓库文件后，在交付、发布或声称完成前必须使用
[`$finish-nix-change` skill](.agents/skills/finish-nix-change/SKILL.md)。它负责格式化、
验证、构建、风险激活、行为验证与回滚；change、恢复、workspace 和远端操作仍由
`$jj-guide` 负责。README 面向使用者记录公开事实，AGENTS.md 记录常驻政策，skills
记录按需工作流，三处不得复制易漂移的命令细节。
