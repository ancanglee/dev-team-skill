# dev-team 使用手册

一套给 AI 编程工具用的虚拟研发团队。九个角色分工，按阶段推进软件项目，支持多个子 agent 并发。新项目从立项开始，已有项目先盘点再迭代。参考实现是 Claude Code，其他工具见 3.6。

这份手册讲三件事：怎么装、怎么用、出问题怎么查。

## 1. 它能做什么

你把一个研发任务交给它，它会：

- 先给你一页提案（目标、范围、角色、阶段、产出），你确认后才开工
- 按需求 → 设计 → 架构 → 开发 → 测试 → 安全 → 交付 → 发布的顺序推进
- 只在三个节点停下来问你：需求冻结、架构冻结、发布前
- 能并行的地方并行，比如多个开发同时做不同模块、架构师同时起前端和后端架构子任务
- 已有项目先做现状盘点，再按变更范围迭代，不动原目录结构
- 卡住会主动停：同一错误两次、单任务三次尝试，到线就出阻塞报告，不会无限重试
- 产出统一落在项目的文档根（默认 `docs/`，已有项目常用 `docs/dev-team/`），交付时附一份给人看的手册

它不做的：替你拍业务决策、替你接受安全风险、替你 git commit 或部署。

## 2. 目录结构

```
dev-team-skill/
├── SKILL.md                      编排入口：启动、波次、Gate、产出规范
├── README.md                     本文件
├── agents/                       九个角色定义
│   ├── project-manager.md
│   ├── product-manager.md
│   ├── interaction-designer.md
│   ├── architect.md
│   ├── developer.md
│   ├── test-engineer.md
│   ├── security-engineer.md
│   ├── tech-writer.md
│   └── red-team.md
├── references/
│   ├── roles-and-scope.md        角色职责、Gate、仲裁、边界的唯一依据
│   ├── loop-control.md           失败预算、重试上限、跳出协议
│   └── templates/                17 份文档模板
└── scripts/
    ├── init-docs.sh              初始化项目的 docs/ 结构
    ├── install.sh                一条命令安装
    └── uninstall.sh              一条命令卸载
```

## 3. 安装

### 3.1 前置条件

- Claude Code（CLI、桌面端或 IDE 插件都行）。这是参考实现，用其他工具见 3.6
- bash
- 项目本身有 git 更好，没有也不影响

### 3.2 用户级安装（所有项目可用）

在 skill 目录下执行：

```bash
bash scripts/install.sh
```

它做两件事：把 skill 链接到 `~/.claude/skills/dev-team`，把九个角色链接到 `~/.claude/agents/`。已经装过的会跳过，不会重复。

从别的位置调用时用相对路径，例如（路径按你实际存放位置调整）：

```bash
bash ../dev-team-skill/scripts/install.sh
```

脚本按自己被调用的位置推算 skill 目录，不需要你填路径。安装生成的是指向该目录的软链接；以后移动了 skill 目录，重跑一次安装即可。

重复执行是安全的。遇到同名文件或指向别处的链接，脚本会跳过并提示，不会覆盖你的东西。

### 3.3 项目级安装（只对这个项目生效）

两种写法，按当前所在位置选一种。

在 skill 目录里，指定项目路径：

```bash
bash scripts/install.sh --project ../my-project
```

不写目录时默认装到当前目录：

```bash
cd ../my-project
bash ../dev-team-skill/scripts/install.sh --project
```

上面的 `../my-project` 和 `../dev-team-skill` 只是示例，按实际目录名调整。

会生成 `<项目>/.claude/skills/dev-team` 和 `<项目>/.claude/agents/`。适合团队共用：把 `.claude/` 和 skill 目录一起提交，成员 clone 下来就能用。skill 目录在不同机器上路径可能不同，团队里最好放进仓库或用固定路径。

### 3.4 验证

1. 重开 Claude Code。
2. 输入 `/agents`，应该能看到九个角色。
3. 说一句「用研发团队帮我做个待办事项应用」，它应该先给提案，而不是直接写代码。

只装了 skill、没装 agents 也能用：编排层会退回 `general-purpose`，把角色说明贴进 prompt。区别是没有独立的工具限制和描述，并发调度也更粗。

### 3.5 在另一台机器上安装

把整个目录复制过去，进入目录执行同一个脚本：

```bash
cd dev-team-skill   # 换成你实际的目录名
bash scripts/install.sh
```

### 3.6 在其他工具里使用（Codex、Cursor、DeepSeek 等）

Skill 的正文是纯 Markdown，角色职责、阶段、Gate、模板都不依赖 Claude Code。Claude Code 只是参考实现，安装脚本也只覆盖它的目录。换到别的 harness，先分清哪些能带走：

| 部分 | 能不能带走 | 说明 |
|---|---|---|
| 角色定义、流程、模板、职责规范 | 能 | 纯文本，任何能读文件的工具都能用 |
| 自动触发、`/dev-team` 命令 | 看工具 | 没有 skill 机制的，把 SKILL.md 写进项目指令或系统提示 |
| 多角色并发 | 看工具 | 支持 subagent 的按角色拆分；不支持的，一个会话里顺序扮演 |
| agent frontmatter（tools、model） | 不能 | 这是 Claude Code 的格式，其他工具会忽略，需要按各自机制改写 |
| install / uninstall 脚本 | 不能 | 只处理 `~/.claude` 和项目的 `.claude/` |

通用接法，四步：

1. 把整个目录放进项目，比如 `.dev-team/`。
2. 让工具先读入口。在项目根放一个 `AGENTS.md`（Codex 等）或 `.cursor/rules/dev-team.mdc`（Cursor），也可以在会话开头直接说「先读 .dev-team/SKILL.md」。入口里写清三件事：读 `SKILL.md` 和 `references/roles-and-scope.md`；要某个角色时读 `agents/<role>.md`；产出统一写文档根（默认 `docs/`，已有项目用 `docs/dev-team/`）。
3. 按工具的并发能力分配角色：
   - 有 subagent：把 `agents/*.md` 当每个角色的系统提示，按 SKILL.md 的波次派发。
   - 没有 subagent：一个会话里顺序扮演角色，切换前重读该角色文件。角色之间只通过 `docs/` 下的文件交接，不靠对话记忆。
4. Gate、停点、产出结构照旧，这些跟工具无关。

启动指令可以直接复制：

```
读 .dev-team/SKILL.md 和 .dev-team/references/roles-and-scope.md。
按 dev-team 的方式推进这个项目：先给我启用提案，等我确认再开工。
需要某个角色时，读 .dev-team/agents/<role>.md，严格按它的职责、产出和回报格式执行。
一次只扮演一个角色，角色之间用文档根下的文件交接。
```

两点注意：

- Codex、Cursor、DeepSeek harness 对子 agent、规则文件和斜杠命令的支持各不相同，版本之间也会变。本手册保证内容可移植，具体接入以当前工具文档为准，不要假设 `agents/*.md` 会被自动识别。
- 并发能力差异最大。没有 subagent 的工具只能串行，波次需要一个个手动推进，成本高一些，流程和产出不变。

## 4. 第一次使用

```
你：用 dev-team 帮我做一个团队周报系统。

Claude：
【启用提案】
目标：让 5 到 10 人的团队每周提交和查看周报
范围：做 提交、查看、提醒；不做 权限体系、移动端
角色：项目经理、产品经理、架构师、开发、测试、技术文档
阶段：需求 → 设计 → 架构 → 开发 → 测试 → 交付 → 发布
停点：需求冻结、架构冻结、发布前
产出：docs/ 下的 PRD、架构、测试报告、交付手册
风险：周报数据敏感，需要安全评审；提醒功能依赖第三方服务

你：确认，但要加安全评审，做权限体系。

Claude：（更新提案）... 确认后开始。
```

第一次开工后，它会：

1. 建文档根（新项目 `docs/`，已有项目 `docs/dev-team/`）
2. 派产品经理写 PRD
3. 需求冻结时停下来问你
4. 架构、开发按波次推进
5. 最后交一份 `docs/08-manual/` 给人看的手册

## 5. 一次项目会怎么推进

| 阶段 | 谁主导 | 产出 | 停不停 |
|---|---|---|---|
| 立项 | 项目经理 | 项目章程 | 自动 |
| 需求 | 产品经理 | PRD、验收标准、NFR | 停（需求冻结） |
| 设计 | 交互设计师 | 交互流程、原型、状态矩阵 | 自动 |
| 架构 | 架构师 | 架构文档、接口契约、模块拆分 | 停（架构冻结） |
| 开发 | 开发工程师 | 代码、单测、自测记录 | 自动 |
| 测试 | 测试工程师 | 测试报告、缺陷分级 | 自动 |
| 安全 | 安全工程师 | 安全报告、高危清零 | 自动，高危即停 |
| 交付 | 技术文档工程师 | 交付手册、部署与排障手册 | 自动 |
| 发布 | 项目经理 + 你 | 发布说明、回滚预案 | 停（发布前） |

停下来的时候会给你：完成了什么、证据在哪、还有什么没定、残余风险、A/B/C 三个选项。没有你的确认，它不会往下走。

### 已有项目怎么走

多一步盘点，少一点改动：

1. **现状盘点。** 架构师带着测试和安全，读代码、跑构建和测试、核对现有文档，产出 `07-project/audit.md`。只读不写，不动你的目录。
2. **定文档根。** 项目已有 `docs/` 且结构不同，就把 dev-team 的产出放进 `docs/dev-team/`，原 `docs/` 不动。
3. **给迭代提案。** 本次做什么、影响哪些模块、怎么验收、怎么回滚，和盘点结论一起确认一次。
4. **按同一张表推进。** 每个阶段只覆盖变更范围：需求写影响面，架构写增量设计，测试带回归范围。

### 卡住了会怎么样

同一动作配同一个错误，连续两次就停；单任务最多三次尝试，评审返工最多两轮；连续两次没有新进展也算卡住。停下后不会硬撑，会写一份 `07-project/blocked.md`，把未完成项、尝试记录、证据和可选下一步交给你。

## 6. 角色清单

| 角色 | 什么时候介入 | 主要产出 |
|---|---|---|
| 项目经理 | 全程 | 章程、计划、风险、状态报告、决策记录 |
| 产品经理 | 需求阶段，后续处理变更 | PRD、验收标准、Non-goals |
| 交互设计师 | 需求冻结后 | 交互流程、状态矩阵、HTML/CSS 原型、设计 token |
| 架构师 | 需求冻结后，兼 tech owner 和 code review 主审 | 架构文档、ADR、接口契约、模块划分、评审结论 |
| 开发工程师 | 契约冻结后，可多实例并行 | 代码、单测、模块说明 |
| 测试工程师 | 需求冻结后（用例与开发并行） | 测试计划、用例、自动化测试、测试报告 |
| 安全工程师 | 架构阶段就介入 | 威胁模型、安全评审、发布检查 |
| 技术文档工程师 | 交付阶段 | 交付手册、使用、测试、部署、排障五份文档 |
| 评审者 | 三个关键节点 | 评审报告、关键假设清单 |

角色可以按项目规模合并，规则在 `references/roles-and-scope.md` 第 7 节。合并的红线只有三条：开发不能给自己验收，拆模块的人不能独占集成验收，评审者必须独立。

## 7. 你的控制权

- **停点**：需求冻结、架构冻结、发布前。其余节点自动流转，结果写文档，你事后可以翻。
- **随时打断**：说「暂停」会输出当前状态和下一步；说「换角色」会调整分工。
- **改规模**：直接说「这个项目小，别全员上」，它会缩到 2 到 3 个角色。
- **改停点**：说「架构不用等我确认」，它会照做。要长期改，见第 9 节。
- **拒绝**：任何 gate 都可以选「修改后重审」。
- **停掉卡住的任务**：说「停下，出阻塞报告」，它会停止重试并给你选项。

## 8. 产出物放在哪

新项目用 `docs/`；已有项目建议 `docs/dev-team/`，下面路径都相对文档根。

```
docs/
  01-product/       prd.md  user-flow.md
  02-design/        interaction.md  states.md  ui-spec.md  tokens.json  prototype/
  03-architecture/  architecture.md  contracts.md  api/  adr/  diagrams/
  04-dev/           development-plan.md  tech-debt.md
  05-test/          test-plan.md  cases.md  report.md
  06-security/      threat-model.md  review.md
  07-project/       charter.md  plan.md  risks.md  decisions.md  audit.md  iteration.md  blocked.md  status/  reviews/
  08-manual/        index.md  overview.md  usage.md  test-manual.md  deployment.md  troubleshooting.md
```

已有项目初始化：

```bash
bash scripts/init-docs.sh <项目根> --docs-dir docs/dev-team
```

- 每份文档开头写：给谁看、解决什么问题、状态（草案 / 已确认 / 已废弃）。
- 流程图、架构图用 Mermaid 写在文档里，能随代码一起 review。
- 目录结构可以用 `bash scripts/init-docs.sh <项目根>` 初始化，脚本不覆盖已有文件。

## 9. 自定义

| 想改什么 | 改哪里 | 注意 |
|---|---|---|
| 角色职责 | `references/roles-and-scope.md` 和 `agents/<role>.md` | 两处要同步，前者是依据，后者是执行 |
| 编排流程、波次、Gate | `SKILL.md` | 不要在 SKILL.md 里重新定义职责，指回角色文件 |
| 文档模板 | `references/templates/` | 改完检查 SKILL.md 和 agent 文件里的路径 |
| 语言 | `SKILL.md` 第 8 节和各 agent 文件 | 文档语言、代码注释语言分别说明 |
| 停点 | `SKILL.md` 第 5 节 | 停点少了风险大，多了效率低 |
| 目录结构 | `scripts/init-docs.sh`、`SKILL.md` 第 6 节、模板索引 | 三处一起改 |

升级：skill 目录是软链接，改完文件立即生效，重开会话即可。如果你改过角色文件，记得留一份自己的版本，避免以后覆盖。

## 10. 常见问题

**Q：为什么没有自动触发？**
Skill 按描述匹配。直接说「用研发团队推进这个项目」，或者输入 `/dev-team`。

**Q：一个小改动也要九个角色？**
不需要。它会先判规模，你也可以直接说小项目，只留必要的角色。

**Q：只想让某个角色干活？**
直接点名：「用架构师评审这个设计」。不需要走完整流程。

**Q：角色 agent 没生效？**
检查 `ls ~/.claude/agents/`，确认九个文件都在且软链接没断（`readlink` 能看到真实路径），然后重开 Claude Code。没装 agent 时 skill 会退回 `general-purpose`，能用但没那么严格。

**Q：多个 agent 改同一个文件冲突了？**
编排层用单写者规则预防：同一个文件同一时刻只有一个 agent 写，共享文件由 owner 统一改。如果还是冲突，说明模块边界没切干净，找架构师重划。

**Q：项目里已经有 docs/ 怎么办？**
初始化脚本不覆盖已有文件。已有目录可以直接复用；如果命名不同，告诉 Claude 按现有结构走。

**Q：token 花得太多？**
并发是有成本的。让它缩小规模、减少角色，或者指定只跑某个阶段。小项目别开全量评审。

**Q：交付手册和代码不一致？**
手册要求每步都实际验证。发现不一致，让技术文档工程师重跑对应步骤；如果代码行为本身有问题，转给对应的 owner，不要直接改手册糊过去。

**Q：能用来做非软件项目吗？**
不建议。角色、契约、测试这些概念是按软件开发设计的，硬套会别扭。

**Q：安全吗？权限会不会太大？**
开发、测试、安全、文档这几个角色有 Bash 权限，能执行构建和测试。首次运行时会请求命令权限，逐条看清楚再批。不要把生产凭据放进会话，也不要在没有备份的目录里跑。

**Q：会不会陷入死循环？**
有硬预算：同一动作同一错误连续两次就停，单任务最多三次尝试，评审返工最多两轮，连续两次无进展也算卡住。到线后写 `07-project/blocked.md`，把未完成项和选项交给你，不会无限重试。

**Q：已经有一个项目，目录结构和这个 skill 不一样，要改吗？**
不用改。它会先读代码、跑构建和测试、盘点现有文档，产出 `07-project/audit.md`；文档放在独立的 `docs/dev-team/`，原目录不移动、不重命名。之后只按本次变更范围迭代。

**Q：能在 Cursor、Codex 或 DeepSeek 这类工具里用吗？**
能，但安装脚本只覆盖 Claude Code。其他工具按 3.6 的通用接法手动接入；角色文件里的 tools、model 字段要按那个工具的机制改写。

## 11. 卸载

在 skill 目录下执行：

```bash
bash scripts/uninstall.sh
```

项目级：

```bash
bash scripts/uninstall.sh --project ../my-project
```

脚本只删指向本 skill 的软链接。同名但不是软链接的文件会保留并提示。项目里已经生成的 `docs/` 和代码不受影响。

上面的脚本只处理 Claude Code 的两个目录。用其他工具时，删掉你手动放进项目的 `.dev-team/` 和对应的规则文件即可。

如果 skill 目录已经被删了，脚本也就没了，手动清理这两个位置：

```bash
rm ~/.claude/skills/dev-team
rm ~/.claude/agents/{project-manager,product-manager,interaction-designer,architect,developer,test-engineer,security-engineer,tech-writer,red-team}.md
```

## 12. 限制

- 子 agent 之间不共享对话记忆，只靠文件交接。所以每个产出物的质量决定了下游能不能接住。
- 并发受模型速率和成本限制，波次别开太宽。
- 角色的判断是模型判断，不是真正的领域专家。安全结论、合规结论、架构决策，仍然需要人来签字。
- 交付手册要求实测，agent 在它拿不到的环境里验证不了，会在报告里标出来，最后需要人补。
- 跨工具使用时，子 agent 并发和自动触发能力取决于宿主工具，不在本 skill 的控制范围内。
- 已有项目的盘点基于代码和现有文档，历史背景缺失时可能判断错。盘点结论需要你确认一次，之后才开始改。
- 预算是硬约束，但不保证识别所有卡点。发现它在原地打转时，直接叫停。
