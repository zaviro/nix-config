---
name: done-any-edit
description: Complete and safely hand off edits in this NixOS configuration repository. Use whenever modifying repository files, especially NixOS, Home Manager, flake inputs, host configuration, or documentation, to select validation, activation, change, publication, and cross-host safeguards.
---

# Done Any Edit

完成任何改动前后都遵循本工作流。本仓库使用 colocated Jujutsu/Git workspace，
`main` 是唯一长期 bookmark；任务中的工作保持为匿名 change，直到完整验证和所需
激活都成功。验证和激活不会自动授权发布：只有用户明确要求发布或推送 `main` 时才可
移动和推送它。修改工作区、历史、bookmark 或远端状态的版本控制操作只使用 `jj`。
Git 仅作为存储后端和第三方工具兼容层；不得执行会写入工作区、index、refs 或远端
状态的 Git 命令。唯一保留的直接 Git 检查是只读的 `git diff --check`。

开始编辑前先让 jj snapshot 当前工作区，并记录 change、diff 和 operation 基线：

```bash
jj status
jj diff --summary
jj log -r '@ | @- | main | main@origin'
jj log -r 'main..@' --reversed
jj op log -n 3
```

新文件无需暂存；jj 会自动 snapshot 未忽略的新文件，使 Flake 求值可以包含它们。
若 `jj status` 未显示预期的新文件，先检查 ignore 或文件大小限制，不得改用 Git
暂存。开始时先判断当前请求与未发布 stack 中已有 changes 的关系：

- **新意图**：与已有 change 可独立理解、验证和回滚。若 `@` 为空且无描述，可直接
  用于当前工作；若 `@` 是已经完成并验证的其他逻辑 change，则运行 `jj new`。取得
  独立 working-copy change 后，使用
  `jj describe -m "<type>(<scope>): <description>"`。
- **延续意图**：请求是在修复、完善、替代或重新验证一个未发布的已有 change。记录
  目标的稳定 Change ID，最终结果必须合入该 change，不得留下平行的最终 change。
- **边界不确定**：先诊断并保留调整空间，不因一次请求或修复尝试过早确定最终边界；
  交付前按最终语义整理。
- 若 `@` 已属于当前逻辑意图，继续在该 change 上工作，不运行 `jj new`；不能仅因
  上一轮已经交付就把延续请求判为新意图。
- 若 `@` 包含其他意图的改动，记录其 Change ID 与文件范围；不得自动 describe、
  split、squash、rebase、abandon、restore 或混入当前任务。无法取得独立工作边界时，
  停止并请示用户。

一个逻辑变更意图默认对应一个最终 change，并且可以跨多个用户请求持续演进。验证、
激活、一次修复尝试、一次工具调用批次或一次对话回合都不构成最终 change 边界。
长时间构建、激活或等待外部操作后，
在继续编辑、switch 或整理历史前重新运行 `jj status` 和 `jj op log -n 3`。若发现
本 agent 未执行的 Jujutsu operation，立即重新核对当前 change、diff 和父 change；
不得假设先前工作仍然存在，也不得自动撤销其他操作者的 operation。

## 文档同步

开始实现时和交付前各做一次文档影响检查。仅在改动改变了读者需要依赖的事实、
操作方式或仓库约定时，更新对应文档；不要为纯重构、内部实现或无语义的格式变更
机械修改文档，也不要新建重复的说明文件。

现有文档按受众分工：

| 文档 | 何时更新 |
| --- | --- |
| `README.md` | 对人可见的主机范围、公开 Flake 接口、主要能力、使用或运维入口发生变化时 |
| `AGENTS.md` | 仓库结构语义、放置规则、跨主机边界或所有协作者都必须遵守的约定发生变化时 |
| `.agents/skills/done-any-edit/SKILL.md` | 编辑完成后的验证、激活、回滚、change 整理或推送工作流发生变化时 |

一项改动可以同时影响多份文档。文档应描述当前事实，并链接到唯一的权威流程，
避免在 `README.md` 或 `AGENTS.md` 复制 skill 中易变的命令细节。交付时说明已更新
哪些文档；若不需要更新，也简要说明文档检查结论。

## 验证

纯文档、注释或格式修改只运行空白检查：

```bash
jj diff --git
git diff --check
```

修改 Nix 配置时，按以下顺序运行：

```bash
nix fmt
jj diff --git
git diff --check
nix flake check
```

完成 `nix flake check` 后，再按实际 diff 选择额外验证：

| 修改范围 | 必需验证 |
| --- | --- |
| `hosts/atlas/**` | atlas 求值和完整构建 |
| `hosts/legion-wsl/**` | legion-wsl 求值和完整构建 |
| `hosts/*/home.nix` 或仅由单一主机导入的模块 | 受影响主机求值和完整构建 |
| 共享模块或共享输入接线 | 当前受影响主机求值和完整构建；所有其他实际导入它的主机求值 |

不在本机无差别构建其他主机；这类构建交由 CI、目标机器或具备缓存/远程 builder 的构建机完成。对每个需验证的主机使用：

```bash
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link
```

完整构建后确认目标确实在 store 中：

```bash
system_toplevel="$(nix build .#nixosConfigurations.atlas.config.system.build.toplevel --no-link --print-out-paths)"
nix path-info "$system_toplevel"
```

## 激活

对于当前机器的低风险 NixOS 或 Home Manager 配置改动，在完成所需格式化、检查和构建后，自动执行 `nh os test ~/nix-config`，成功后立即执行 `nh os switch ~/nix-config`。不要使用 `sudo nh os`，也不要运行 `nh home switch`。纯文档、注释或格式修改不激活。

以下变更可能让机器无法正常使用或失去恢复通道，必须先报告风险并取得用户确认，不得自动激活：Disko、引导加载器、内核或 initrd、网络（包括 NetworkManager、Tailscale、SSH）、防火墙、认证或提权、显示管理器、桌面会话或图形栈。共享模块仍须遵守仓库的跨主机范围约束。

激活前先确认新的 `toplevel` 已实现，并记录当前系统 generation：

```bash
current_generation="$(readlink /nix/var/nix/profiles/system | sed -n 's/^system-\\([0-9]\\+\\)-link$/\\1/p')"
test -n "$current_generation"
```

`nh os test` 会真实激活配置，但不设为下次启动默认；`nh os switch` 会重新运行激活并持久化该配置。`switch` 成功退出即可视为成功，无需额外健康检查。若构建或激活前校验失败，系统未切换，绝不执行回滚。

`nh os test` 的真实环境激活是关键的真实测试阶段，适用于所有改动，而不仅是特定类别的运行时配置。test 成功后，agent 必须根据本次改动自行设法设计并执行足以证明改动已在真实环境中生效的验证；验证通过后，才可继续执行 `nh os switch`。无法完成有意义的行为验证时，必须明确报告为“未完成行为验证”，不得仅凭构建或激活成功声称功能已完成。

`nh os test` 的临时闭包不会成为 system profile generation。若需结束成功的测试或测试激活已开始但失败，使用已记录的持久 generation 重新激活；不要使用 `nh os rollback`：

```bash
/nix/var/nix/profiles/system-"$current_generation"-link/bin/switch-to-configuration switch
```

对 `nh os switch` 而言，只有输出表明已开始激活而操作失败时，才执行：

```bash
nh os rollback --to "$current_generation"
```

回滚也失败时立即停止并向用户报告；不要尝试 Disko 或其他破坏性恢复操作。

WSL 仅在目标机器上按下列顺序执行：

```bash
nh os test ~/nix-config
nh os switch ~/nix-config
```

`nh` 不可用时，才使用恢复命令：

```bash
sudo nixos-rebuild switch --flake ~/nix-config
```

常规构建、`test` 与 `switch` 都不得执行 Disko 脚本。

## 跨主机与 SSH

默认只管理当前主机。不得远程写入、激活或 SSH 到另一台主机，除非用户明确要求跨机器操作。Tailscale SSH 的简短主机名是：

```bash
tailscale ssh zaviro@atlas
tailscale ssh zaviro@legion-wsl
```

仅在用户明确要求 SSH 访问另一台主机时使用这些命令；不得将其用于日常验证、构建、激活或未授权的跨机器操作。

## Flake lock

目录移动、模块拆分和普通配置修改不得改变 `flake.lock`。改变 input 拓扑（新增、删除、URL 或 `follows`）后必须运行 `nix flake lock`，但不得借此隐式升级依赖。只有用户明确要求更新、升级、最新版本或指定 revision 时，才可运行：

```bash
nix flake update <input-name>
nix flake update
```

更新依赖应形成独立 change，并完成所有受影响主机的必要验证。不要自动调整 `home.stateVersion` 或 `system.stateVersion`。

## Change 生命周期与发布

一个逻辑变更意图默认对应一个最终 Jujutsu change。它可以跨多个用户请求持续演进；
整个意图期间的诊断修正、验证失败调整和行为测试完善都属于同一最终 change。确定
描述后，使用
`jj describe` 设置或更新 Conventional Commit 描述；不要用 `jj commit` 模拟 Git
提交，也不要仅因阶段性验证成功就创建新的空 change。

完成验证及所需的 `test`/`switch` 后，核对当前 change 和最终 diff：

```bash
jj status
jj diff --summary
jj diff --git
git diff --check
jj show @
```

若当前 change 混有多个独立意图，先核对完整 diff，再使用 `jj split` 的明确 fileset
拆分；不得用 `jj commit <fileset>` 模拟 Git staging。若任务过程中产生了多个 changes，
交付前必须检查边界：后续 change 只是修正、完善或取代前一个 change 时，使用
`jj squash` 合并。只有两个修改同时满足下列条件时才保留为不同 changes：

1. 表达不同的用户意图；
2. 任一 change 单独存在时配置仍然合理；
3. 可以分别验证；
4. 可以分别回滚而不会留下无意义的中间状态。

若延续意图的目标 change 不在当前 stack 顶端，不要求直接 `jj edit` 旧 change。为了
在当前完整 tree 上安全实现和验证，可以在空 `@` 建立临时工作 change，完成验证后
运行：

```bash
jj squash --from <work-change-id> --into <target-change-id>
jj log -r 'conflicts() & (main..@)'
```

随后检查所有被 rebase 的后代和最终 diff，确认临时工作 change 已消失，且最终只有
目标逻辑 change 表达该意图。临时工作 change 是实现机制，不代表新的最终边界。

最终边界确认后，记录已完成逻辑 change 的稳定 Change ID，但不为结束任务机械运行
`jj new`。保留该 change 为 `@` 是正常的 Jujutsu 工作区状态，不表示改动尚未整理。
只有后续请求被确认是独立的新逻辑意图时，才在开始修改前运行：

```bash
jj new
jj describe -m "<type>(<scope>): <description>"
jj status
jj log -r '@ | @-'
```

确认新 `@` 的父级是此前完成的 change，并且新 `@` 只承载新意图。这一步不构成发布，
也不得移动 `main`。若 squash 或 rebase 已经留下空 `@`，新意图可直接认领它，无需
再次运行 `jj new`。空 `@` 只是工作区状态，不能作为意图边界的判断依据；若当前 `@`
包含来源或完成状态不明的改动，不得用 `jj new` 绕过边界核对。

默认完成本地 change、验证和所需的 `test`/`switch` 后仍不发布；“完成”“交付”或
普通编辑请求均不构成移动或推送 `main` 的授权。不得为日常 WIP 创建长期 bookmark。
用户需要远端备份、跨机器继续或 agent 交接而尚未要求发布时，只能创建短期、按任务
命名的 bookmark（如 `agent/<task>`）或使用 `jj git push --change @` 创建 `push-*`；
不得推送 `main` 或创建/共享 `next`。任务完成后删除这些临时 bookmark。用户明确
要求暂不写描述时，可以保留未描述 change，并报告其 Change ID、父 change 与 diff
范围。

只有收到用户明确的发布指示后，才获取远端状态并检查 `main`。若 fetch 失败、
bookmark 出现冲突，或远端状态无法确认，立即停止，不得猜测或覆盖：

```bash
jj git fetch --remote origin
jj bookmark list main --all-remotes
jj log -r 'main | main@origin'
```

发布前先把本次任务 stack 顶端的稳定 Change ID 记录为候选 revision；不得依赖它
恰好位于 `@` 或 `@-`：

```bash
candidate='<task-change-id>'
jj log -r "$candidate"
```

若远端 `main` 已前进，将候选 stack rebase 到更新后的本地 `main`：

```bash
jj rebase -b "$candidate" -o main
jj status
jj log -r "conflicts() & (main..$candidate)"
```

jj 可以把冲突记录在 change 中，因此命令成功退出不等于没有冲突。出现冲突立即
停止并请示用户。rebase 后重新核对候选 diff；若候选 tree 发生变化，重新运行所有
受影响的验证、构建和激活。

确认待发布范围只包含本次任务，并且所有 change 都有准确描述、没有冲突：

```bash
jj log -r "main@origin..$candidate" --reversed
jj diff --from main@origin --to "$candidate"
jj log -r "conflicts() & (main@origin..$candidate)"
```

发现本次任务以外的既有 change 时不得发布。审查通过后仅向前移动 `main`，先 dry
run，再执行整个任务唯一一次远端发布：

```bash
jj bookmark move main --to "$candidate"
jj git push --remote origin --bookmark main --dry-run
jj git push --remote origin --bookmark main
```

不得使用允许 `main` 向后或横向移动的选项，也不得重写已发布的 `main`。push 被
拒绝或 dry run 显示意外范围时立即停止；不要自动重试或改推其他 bookmark。push
成功后用下列命令确认本地与远端 `main` 同步：

```bash
jj bookmark list main --all-remotes
jj log -r '@ | @- | main | main@origin'
```

对于尚未发布的误操作，先运行 `jj op log` 确认目标 operation；只有能确定最后一次
operation 就是待撤销操作时才运行 `jj undo`，更早的恢复须先用
`jj --at-op=OPERATION_ID log` 审查并请示用户。不得用 Git 恢复命令。对于已经
发布到 `main` 的错误，创建新的修复或 revert change，重新完成本工作流并向前发布；
不得撤销远端操作或把 `main` 后移。
