# dev-team

**English** | [中文](README.zh-CN.md)

A virtual R&D team for AI coding tools. Nine roles, a staged process for software projects, and multiple subagents running in parallel. New projects start at kickoff; existing projects get audited first. The reference implementation is Claude Code — other tools are covered in section 3.6.

This guide covers install, usage, and troubleshooting.

## 1. What it does

Hand it a development task and it will:

- Give you a one-page proposal first (goal, scope, roles, phases, deliverables). Nothing starts until you confirm.
- Move through requirements → design → architecture → development → testing → security → delivery → release.
- Stop for you at three points only: requirements freeze, architecture freeze, pre-release.
- Parallelize where it can. Several developers on different modules, or the architect running front-end and back-end architecture subtasks at once.
- For an existing project, audit what's there before changing anything, then iterate within the change scope without touching the original directory layout.
- Stop itself when stuck. Same error twice, or three attempts on one task, and it writes a blocked report rather than retrying forever.
- Write deliverables to the project's docs root (`docs/` by default; existing projects often use `docs/dev-team/`), and hand over a human-facing manual at delivery.

What it won't do: make business decisions for you, accept security risk on your behalf, or run git commit and deploy.

## 2. Layout

```
dev-team-skill/
├── SKILL.md                      Orchestration entry: kickoff, waves, gates, output rules
├── README.md                     This file (English)
├── README.zh-CN.md               Chinese version
├── LICENSE                       Apache License 2.0
├── NOTICE                        Attribution notice
├── agents/                       Nine role definitions
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
│   ├── roles-and-scope.md        Single source of truth for role scope, gates, arbitration, boundaries
│   ├── loop-control.md           Failure budgets, retry caps, breakout protocol
│   └── templates/                17 document templates
└── scripts/
    ├── init-docs.sh              Set up the docs/ skeleton in a project
    ├── install.sh                One-command install
    └── uninstall.sh              One-command uninstall
```

## 3. Install

### 3.1 Prerequisites

- Claude Code, as CLI, desktop app, or IDE extension. This is the reference implementation; section 3.6 covers other tools.
- bash
- git in the target project is better, but not required.

### 3.2 User-level install (available in every project)

From the skill directory:

```bash
bash scripts/install.sh
```

It does two things: links the skill to `~/.claude/skills/dev-team` and the nine roles to `~/.claude/agents/`. Anything already installed is skipped, not duplicated.

To run it from elsewhere, use a relative path (adjust to where you actually keep the directory):

```bash
bash ../dev-team-skill/scripts/install.sh
```

The script derives the skill directory from its own location, so you don't pass a path. What it creates are symlinks into that directory. If you move the skill directory later, rerun the install.

Running it again is safe. If a file or a link to somewhere else already has the same name, the script skips it and says so. It won't overwrite your files.

### 3.3 Project-level install (this project only)

Two forms. Pick the one that matches where you are.

From the skill directory, name the project:

```bash
bash scripts/install.sh --project ../my-project
```

Or install into the current directory:

```bash
cd ../my-project
bash ../dev-team-skill/scripts/install.sh --project
```

The `../my-project` and `../dev-team-skill` above are examples; use your real directory names.

This creates `<project>/.claude/skills/dev-team` and `<project>/.claude/agents/`. Good for teams sharing one setup: commit both `.claude/` and the skill directory, and everyone who clones it is ready. Skill directories can live at different paths on different machines, so putting it in the repo or at a fixed path is your best bet.

### 3.4 Verify

1. Restart Claude Code.
2. Type `/agents`. You should see all nine roles.
3. Say "use the dev-team to build me a todo app". It should hand you a proposal first, not start writing code.

Skill-only works too, without the agents. The orchestration layer falls back to `general-purpose` and pastes the role definition into the prompt. The difference is no separate tool restrictions or descriptions, and coarser parallel scheduling.

### 3.5 Installing on another machine

Copy the whole directory over, enter it, and run the same script:

```bash
cd dev-team-skill   # use your actual directory name
bash scripts/install.sh
```

### 3.6 Using it in other tools (Codex, Cursor, DeepSeek, and friends)

The skill is plain Markdown. Role scope, phases, gates, and templates don't depend on Claude Code. Claude Code is just the reference implementation, and the install scripts only cover its directories. Moving to another harness starts with knowing what travels:

| Part | Portable? | Notes |
|---|---|---|
| Role definitions, process, templates, scope rules | Yes | Plain text; any tool that can read files can use them |
| Auto-trigger, `/dev-team` command | Depends on the tool | Without a skill mechanism, put SKILL.md in the project instructions or system prompt |
| Multi-role parallelism | Depends on the tool | If it has subagents, split by role; if not, play the roles sequentially in one session |
| Agent frontmatter (tools, model) | No | Claude Code's format; other tools ignore it, so rewrite it per tool |
| install / uninstall scripts | No | They only handle `~/.claude` and the project's `.claude/` |

The generic wiring is four steps:

1. Put the whole directory into the project, e.g. `.dev-team/`.
2. Tell the tool to read the entry point. Either add an `AGENTS.md` at the project root (Codex and similar) or `.cursor/rules/dev-team.mdc` (Cursor), or just say "read .dev-team/SKILL.md first" at the start of a session. The entry point needs three things: read `SKILL.md` and `references/roles-and-scope.md`; read `agents/<role>.md` when a role is needed; write outputs to the docs root (`docs/` by default, `docs/dev-team/` for existing projects).
3. Assign roles according to the tool's concurrency:
   - With subagents: treat `agents/*.md` as each role's system prompt and dispatch waves as SKILL.md describes.
   - Without them: play the roles one at a time in a single session and reread the role file before switching. Roles hand off through files under the docs root, not through conversational memory.
4. Gates, stop points, and output structure stay as they are. None of that depends on the tool.

A startup prompt you can copy:

```
Read .dev-team/SKILL.md and .dev-team/references/roles-and-scope.md.
Run this project the dev-team way: give me the kickoff proposal first, and wait for my confirmation before starting.
When a role is needed, read .dev-team/agents/<role>.md and follow its scope, outputs, and report format exactly.
Play one role at a time, and hand off between roles through files under the docs root.
```

Two caveats:

- Support for subagents, rule files, and slash commands varies across Codex, Cursor, and DeepSeek harnesses, and shifts between versions. This guide guarantees the content is portable; the actual wiring follows whatever the current tool documents. Don't assume `agents/*.md` will be picked up automatically.
- Concurrency is where the difference bites hardest. Tools without subagents can only go serially, so waves have to be pushed along by hand. More effort, same process and outputs.

## 4. First run

```
You: Use dev-team to build me a team weekly-report system.

Claude:
【Kickoff proposal】
Goal: let a 5–10 person team submit and read weekly reports
Scope: build submit, view, remind; skip the permission system and mobile
Roles: project manager, product manager, architect, developer, tester, tech writer
Phases: requirements → design → architecture → development → testing → delivery → release
Stop points: requirements freeze, architecture freeze, pre-release
Deliverables: PRD, architecture, test report, delivery manual under docs/
Risks: weekly reports carry sensitive data, so a security review is needed; the reminder feature depends on a third-party service

You: Confirmed, but add a security review and build the permission system.

Claude: (updates the proposal) ... starts after you confirm.
```

Once work starts, it will:

1. Create the docs root (`docs/` for a new project, `docs/dev-team/` for an existing one)
2. Dispatch the product manager to write the PRD
3. Stop and ask you at requirements freeze
4. Move architecture and development forward in waves
5. Hand over a human-facing manual in `docs/08-manual/`

## 5. How a project moves

| Phase | Lead | Output | Stops? |
|---|---|---|---|
| Kickoff | Project manager | Project charter | Auto |
| Requirements | Product manager | PRD, acceptance criteria, NFRs | Stop (requirements freeze) |
| Design | Interaction designer | Flows, prototype, state matrix | Auto |
| Architecture | Architect | Architecture doc, interface contracts, module split | Stop (architecture freeze) |
| Development | Developers | Code, unit tests, self-test notes | Auto |
| Testing | Test engineer | Test report, defect severity | Auto |
| Security | Security engineer | Security report, high-severity issues cleared | Auto; stops on any high-severity finding |
| Delivery | Tech writer | Delivery, deployment, and troubleshooting manuals | Auto |
| Release | Project manager + you | Release notes, rollback plan | Stop (pre-release) |

At a stop point you get: what's done, where the evidence is, what's still open, residual risk, and three options A/B/C. It won't move on without your confirmation.

### Existing projects

One extra step of audit up front, fewer changes afterward:

1. **Audit.** The architect, with testing and security, reads the code, runs the build and tests, and checks existing docs. Output goes to `07-project/audit.md`. Read-only: your directories stay untouched.
2. **Pick the docs root.** If the project already has a `docs/` with a different structure, dev-team output goes to `docs/dev-team/` and the original `docs/` is left alone.
3. **Iteration proposal.** What this round does, which modules it touches, how it's accepted, how it rolls back — confirmed once, together with the audit findings.
4. **Same table from there.** Each phase covers only the change scope: requirements describe the impact surface, architecture covers the delta, testing carries a regression scope.

### When it gets stuck

The same action producing the same error twice stops it. One task gets at most three attempts, review rework at most two rounds, and two consecutive rounds without progress also count as stuck. It doesn't push through — it writes `07-project/blocked.md` with unfinished items, attempts made, evidence, and the options it sees, and hands that to you.

## 6. Roles

| Role | When it joins | Main outputs |
|---|---|---|
| Project manager | Throughout | Charter, plan, risks, status reports, decision log |
| Product manager | Requirements, and later change requests | PRD, acceptance criteria, non-goals |
| Interaction designer | After requirements freeze | User flows, state matrix, HTML/CSS prototype, design tokens |
| Architect | After requirements freeze; also tech owner and lead code reviewer | Architecture doc, ADRs, interface contracts, module boundaries, review verdicts |
| Developer | After contracts freeze; multiple instances in parallel | Code, unit tests, module notes |
| Test engineer | After requirements freeze (test cases run alongside development) | Test plan, cases, automation, test report |
| Security engineer | Joins at the architecture phase | Threat model, security reviews, release checks |
| Tech writer | Delivery phase | Five docs: delivery, usage, testing, deployment, troubleshooting |
| Red team | Three key checkpoints | Review reports, list of unverified assumptions |

Roles can be merged for smaller projects. The rules are in section 7 of `references/roles-and-scope.md`. Three lines can't be crossed: developers can't accept their own work, whoever splits the modules can't also own the integration acceptance, and the red team stays independent.

## 7. What you control

- **Stop points**: requirements freeze, architecture freeze, pre-release. Everything else flows automatically, with results written to docs you can read later.
- **Interrupt any time**: "pause" prints the current state and next step; "switch roles" reassigns work.
- **Change the scale**: say "this is a small project, don't bring everyone" and it drops to 2–3 roles.
- **Change the stop points**: say "no need to wait for me at architecture" and it complies. For a lasting change, see section 9.
- **Reject**: every gate has a "revise and re-review" option.
- **Kill a stuck task**: say "stop, write a blocked report" and it stops retrying and gives you options.

## 8. Where outputs go

`docs/` for new projects; `docs/dev-team/` is recommended for existing ones. Paths below are relative to the docs root.

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

Initialize an existing project:

```bash
bash scripts/init-docs.sh <project-root> --docs-dir docs/dev-team
```

- Start each document with: who reads it, what problem it solves, and status (draft / confirmed / deprecated).
- Flow, architecture, and state diagrams go in the doc as Mermaid, so they get reviewed with the code.
- You can create the directory structure with `bash scripts/init-docs.sh <project-root>`. The script never overwrites existing files.

## 9. Customizing

| What you want to change | Where | Watch out |
|---|---|---|
| Role scope | `references/roles-and-scope.md` and `agents/<role>.md` | Keep both in sync; the former is the authority, the latter is execution |
| Orchestration, waves, gates | `SKILL.md` | Don't redefine scope in SKILL.md; point back to the role files |
| Document templates | `references/templates/` | After editing, check the paths referenced in SKILL.md and the agent files |
| Language | Section 8 of `SKILL.md` and each agent file | Doc language and code-comment language are specified separately |
| Stop points | Section 5 of `SKILL.md` | Fewer stops, more risk; more stops, less throughput |
| Directory structure | `scripts/init-docs.sh`, section 6 of `SKILL.md`, template index | Change all three together |

Upgrading: the skill directory is a symlink, so file edits take effect immediately. Restart the session. If you've customized role files, keep your own copy somewhere to avoid losing it in a future update.

## 10. FAQ

**Q: Why didn't it trigger automatically?**
Skills match on their description. Say "run this project with the dev-team", or type `/dev-team`.

**Q: Does a small change really need nine roles?**
No. It judges the scale first, and you can say it's a small project and keep only what's needed.

**Q: I just want one role to do something.**
Name it: "have the architect review this design". No need to run the whole process.

**Q: The role agents aren't working.**
Check `ls ~/.claude/agents/` — all nine files should be there and the symlinks intact (`readlink` shows the real path). Then restart Claude Code. Without the agents, the skill falls back to `general-purpose`: usable, less strict.

**Q: Multiple agents changed the same file and conflicted.**
The orchestration layer prevents this with a single-writer rule: one agent writes a given file at a time, and shared files are edited by their owner. If conflicts still happen, the module boundaries were cut badly — have the architect redraw them.

**Q: The project already has a docs/ directory.**
The init script doesn't overwrite existing files. You can reuse the directory; if the naming differs, tell Claude to follow the existing structure.

**Q: Token usage is high.**
Parallelism costs money. Shrink the scale, use fewer roles, or run just one phase. Skip the full review on small projects.

**Q: The delivery manual doesn't match the code.**
The manual requires every step to be verified for real. If you find a mismatch, have the tech writer rerun that step. If the code itself is wrong, route it to the owner — don't patch the manual to paper over it.

**Q: Can I use it for non-software projects?**
Not really. Roles, contracts, and tests are designed around software development; forcing them elsewhere gets awkward.

**Q: Is it safe? Aren't the permissions too broad?**
The developer, tester, security, and tech writer roles have Bash access, so they can run builds and tests. You'll be asked to approve commands on first run — read each one. Don't put production credentials in the session, and don't run it in a directory without backups.

**Q: Can it get stuck in a loop?**
It has hard budgets: the same action with the same error twice stops it, one task gets at most three attempts, review rework at most two rounds, and two consecutive no-progress rounds also count as stuck. At the limit it writes `07-project/blocked.md` and hands you the unfinished items and options. No endless retries.

**Q: I already have a project whose layout differs from this skill. Do I need to restructure it?**
No. It reads the code, runs the build and tests, audits existing docs, and writes `07-project/audit.md`. Documentation goes into a separate `docs/dev-team/`; the original directory is never moved or renamed. After that it only iterates within the current change scope.

**Q: Can I use it in Cursor, Codex, or DeepSeek?**
Yes, but the install scripts only cover Claude Code. Wire other tools by hand as described in 3.6; the tools and model fields in the role files need rewriting for each tool's mechanism.

## 11. Uninstall

From the skill directory:

```bash
bash scripts/uninstall.sh
```

Project-level:

```bash
bash scripts/uninstall.sh --project ../my-project
```

The script only removes symlinks that point at this skill. Same-named files that aren't symlinks stay, with a notice. Generated `docs/` and your code are untouched.

Those scripts only handle Claude Code's two directories. For other tools, delete the `.dev-team/` you placed in the project and the rule file you added.

If the skill directory is already gone, the script is gone with it. Clean up the two locations by hand:

```bash
rm ~/.claude/skills/dev-team
rm ~/.claude/agents/{project-manager,product-manager,interaction-designer,architect,developer,test-engineer,security-engineer,tech-writer,red-team}.md
```

## 12. Limits

- Subagents don't share conversational memory; they hand off through files. So the quality of each artifact decides whether the next stage can pick it up.
- Parallelism is bounded by model rate limits and cost. Don't open a wave too wide.
- Role judgment is model judgment, not real domain expertise. Security findings, compliance findings, and architecture decisions still need a human signature.
- The delivery manual requires hands-on verification. Agents can't verify environments they can't reach and will flag that in the report; a human fills the gap.
- In other tools, subagent parallelism and auto-triggering depend on the host. Outside this skill's control.
- The audit of an existing project is based on code and current docs. Missing history can lead to wrong conclusions. Confirm the audit once before changes begin.
- Budgets are hard limits but don't catch every dead end. If you see it spinning in place, call a stop.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
