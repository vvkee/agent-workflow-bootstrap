# agent-workflow-bootstrap

轻量通用 Agent Stack Bootstrap。

目标：
- 一份仓库
- 一个安装入口
- 一套全局模板
- 四个统一命令入口
- 尽量不污染每个 repo

默认分工：
- Claude Code = 主写手（默认）
- OpenCode = 备选主写手（`AGENT_BUILD_DRIVER=opencode` 切换）
- Codex = 冷审
- Hermes = research / memory / skills 外环

默认工作流：
1. 小改动：`ai-build`
2. 正常开发：`ai-build` -> `ai-review`
3. 需要外部研究：`ai-research` -> `ai-build` -> `ai-review`

原则：
- 默认单主代理，不做多 agent 接力写代码
- review finding 是 hypothesis，不是自动施工命令
- plan 只在复杂任务出现，默认直接 build
- 规则文件要短、硬、稳定
- repo 内只允许临时产物进入 `.ai/tmp/` 和 `.codex/tmp/`

说明：
- 仓库名暂时仍为 agent-workflow-bootstrap，但 v1.1 scope 已扩成更通用的 agent stack bootstrap
- v1.1 仍然是轻量 bootstrap，不是自动编排平台
- 维护者范围、边界与 release criteria 见：`docs/roadmap.md`

## 项目结构

```text
agent-workflow-bootstrap/
  install.sh
  bootstrap.sh
  docs/
    roadmap.md
  env/
    workflow.env.example
  lib/
    common.sh
    prompts.sh
  bin/
    ai-build
    ai-review
    ai-research
    ai-doctor
  templates/
    claude/CLAUDE.md
    opencode/AGENTS.md
    codex/AGENTS.md
    codex/skills/repo-review/SKILL.md
    codex/skills/repo-brief/SKILL.md
    shared/output-contract.md
    hermes/SOUL.md
    hermes/config.fragment.yaml
  verify/
    smoke.sh
    test-install.sh
    e2e.sh
    fixtures/
```

## 安装

本地源码安装：

```bash
cd ~/codes/agent-workflow-bootstrap
./install.sh
```

GitHub 直接安装：

```bash
curl -fsSL https://raw.githubusercontent.com/vvkee/agent-workflow-bootstrap/main/install.sh | bash
# 或
curl -fsSL https://raw.githubusercontent.com/vvkee/agent-workflow-bootstrap/main/bootstrap.sh | bash
```

默认行为：
- 复制全局模板到用户目录（Claude、OpenCode、Codex、Hermes）
- 在 `~/.local/bin/` 下创建命令入口的符号链接
- 若 `ai-research` 已被现有命令占用，自动回退安装为 `ai-research-workflow`
- 在 `~/.config/agent-stack/workflow.env` 初始化共享 env 文件（若不存在）
- 在 `~/.config/agent-stack/output-contract.md` 安装共享输出契约
- GitHub 直接安装会先把仓库落到稳定本地目录，再创建命令软链
- 默认不覆写已有文件
- 默认不改 Hermes 配置；如需自动补 `skills.external_dirs`，使用 `--patch-hermes-skills`

常用参数：

```bash
./install.sh --force
./install.sh --patch-hermes-skills
./install.sh --force --patch-hermes-skills
```

## 5 分钟快速试用

```bash
./install.sh
ai-doctor
ai-build "修复一个小 bug"
ai-review
ai-research "调研某个库的最佳实践"
```

如果你想临时切主写手或调试 prompt：

```bash
ai-build --driver opencode --dump-prompt "实现一个小功能"
ai-review --mode working-tree --include-untracked src/new-file.ts --dump-prompt
ai-research --profile thin --toolsets web --dump-prompt "调研发布策略"
```

## 四个命令

### `ai-build`
- 默认调用 Claude Code，或根据 `AGENT_BUILD_DRIVER` / `--driver` 调用 OpenCode
- 让主写手自己读 repo、自主短计划、实现、验证
- 支持：`--model`、`--no-auto-approve`、`--dump-prompt`
- 默认要求输出：改动文件 / 核心原因 / 验证结果 / 剩余风险

### `ai-review`
- 生成当前 repo 的 review diff
- 调 Codex 做只读审查
- 支持：`--mode`、`--model`、`--include-untracked <path>`（可重复传入）、`--dump-prompt`
- 默认只接受高价值输出：`PASS | REQUEST_CHANGES`

### `ai-research`
- 调 Hermes 做外部资料研究
- 支持：`--profile`、`--toolsets`、`--dump-prompt`
- 默认输出：facts / unknowns / risks / recommendation

### `ai-doctor`
- 检查命令、全局模板、共享 env、repo 状态、临时目录
- 优先检查当前配置的主执行器
- 会打印当前 effective config，便于排查 env 覆盖问题

## 共享环境变量

安装后会生成：
- `~/.config/agent-stack/workflow.env`

默认变量见：
- `env/workflow.env.example`

重点变量：
- `AGENT_BUILD_DRIVER` — 主写手选择：`claude`（默认）| `opencode`
- `CLAUDE_CMD`
- `OPENCODE_CMD`
- `CODEX_CMD`
- `HERMES_CMD`
- `OPENCODE_BUILD_AGENT`
- `HERMES_RESEARCH_PROFILE`
- `HERMES_RESEARCH_TOOLSETS`

## 临时目录约定

所有 repo 本地中间产物统一放：
- `<repo>/.ai/tmp/`
- `<repo>/.codex/tmp/`

v1 不默认新增：
- repo 根目录 `code_review.md`
- repo 根目录 `opencode.json`
- 一堆计划 markdown

## 已知边界

- `ai-build` 默认使用 Claude Code CLI（`claude`）；如未安装可通过 `AGENT_BUILD_DRIVER=opencode` 或 `--driver opencode` 切换到 OpenCode
- `ai-review` 默认优先审查当前工作区中已跟踪文件的 diff；若要把新的未跟踪文本文件纳入 scope，需显式加 `--include-untracked`
- `ai-research` 默认使用 Hermes CLI；如配置了专门 profile，可在 `workflow.env` 或命令行参数中指定
- v1.1 不实现自动 review loop、自动 apply-review、多 agent 自动编排
- 这是一个 shell-only bootstrap，不负责替你做最终工程裁决

## 验证

开发/发布前至少运行：

```bash
bash verify/smoke.sh
```
