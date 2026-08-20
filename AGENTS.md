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

## 激活自主性与连接安全

当前主机的非破坏性 NixOS 或 Home Manager 改动在完成所需构建后，默认自主执行
`nh os test`、由 agent 自行设计的相称行为验证与 `nh os switch`。是否请求确认根据
本次激活的实际副作用、可恢复性、控制通道影响和用户工作中断风险判断。

任何可能中断当前 agent 与机器连接的操作，执行前必须建立不依赖后续工具调用的
自动恢复路径。受保护的激活、失败恢复和控制通道复检必须包含在同一个有界事务中，
并预先启动独立恢复 watchdog；需要 test 激活后自适应探索时，事务可以跨多次工具调用，
但每次返回 agent 前 watchdog 必须保持有效并受总时长硬限制。激活必须具备确定恢复点
与所需自动恢复路径。具体分级与恢复流程由
[`$finish-nix-change` skill](.agents/skills/finish-nix-change/SKILL.md) 负责。

## 版本控制政策

本仓库使用 colocated Jujutsu/Git workspace。Jujutsu 管理工作区、历史、bookmark 与
远端写操作；Git 仅作为存储后端和只读兼容层，不得用 Git 修改工作区、index、历史、
refs 或远端状态。

远端长期 bookmark 只有 `main` 与 `next`。`main` 是稳定发布线，只能在用户明确要求发布
或推送时向前移动；已发布错误以新的 forward change 修正，不得回退、侧移或重写。
`next` 是云端与本地共同开发所共享的最新已选定实验集成 tip；它不充当日常 change owner，
本地例行工作保持为位于明确基线之上的匿名 changes。

完成、验证和激活均不构成 `main` 或其他 bookmark 的发布授权。通过
`$finish-nix-change` 完成本地 change 后，默认将精确的最新已完成实验 tip 同步到
`next`，除非用户明确要求仅保留本地或必要验证尚未完成；这是仅限 `next` 的常驻发布
授权。这项常驻授权只涵盖把 `next` 指向该精确已完成 tip 所需的向前、向后、侧向或历史
改写更新；非 local-only 任务的服务端对象复核是完成门禁。同步必须通过 Jujutsu 基于已
抓取 remote-tracking state 的 lease safety 推送。远端 tip 与记录 lease 不一致时必须停止
并重新审阅，不得绕过 lease。远端备份、跨机器继续或 agent 交接可以使用按任务命名的
短期 bookmark 或 `push-*`，但不得建立其他长期开发线。

change 边界按维护者可能合理地作为不同步骤落地、保留或回滚的有意状态划分，不按消息、
验证阶段或工具批次划分。步骤之间可以有明确依赖。开始任务的 agent 在首次编辑前负责
建立或复用正确的 change；任务结束时不为未知的下一任务预建边界。保持简单请求连贯，
不得混入、改写或丢弃来源不明、属于用户或其他操作者的工作。

本地明确拥有且未发布的 stack 可以按逻辑 ownership、依赖与审阅价值整理。默认使用
当前 workspace，额外 workspace 不自动授权 bookmark、远端或发布。首次编辑仓库文件前
或执行任何 Jujutsu 操作时，必须使用
[`$jj-guide` skill](.agents/skills/jj-guide/SKILL.md)；具体边界、整理和 workspace case
由该 skill 负责，且不能扩大本文件规定的权限。

默认目标是当前主机。只有用户明确指定另一主机时，才编辑或完整构建它的主机专属
配置；修改共享源必须由请求本身涵盖或由用户明确接受其跨主机影响。在当前机器上对
另一公开 `nixosConfiguration` 做不改变机器状态的本地求值，可以作为共享变更的兼容性
检查，不算跨机器操作；它不授权 SSH、写入或激活另一机器。不得提交明文凭证，
`home.stateVersion` 与 `system.stateVersion` 保持 `26.05`。目录重构不得更新
`flake.lock`；input 拓扑变化只授权重建与新拓扑一致的 lock graph，只有用户明确要求
依赖升级时才可更新已锁定 input 的版本。依赖升级必须作为独立意图完成和验证。

修改过仓库文件后，在交付、发布或声称完成前必须使用
[`$finish-nix-change` skill](.agents/skills/finish-nix-change/SKILL.md)。它负责格式化、
验证、构建、风险激活、行为验证以及 activation recovery/rollback；Jujutsu change
ownership、历史与冲突处理、operation recovery、workspace、bookmark 和远端操作由
`$jj-guide` 负责。README 面向使用者记录公开事实，AGENTS.md 记录常驻政策，skills
记录按需工作流，三处不得复制易漂移的命令细节。
