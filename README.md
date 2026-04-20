# agent-workflow-bootstrap

轻量通用 Agent Workflow Bootstrap v1。

目标：
- 一份仓库
- 一个 `install.sh`
- 一套全局模板
- 四个统一命令入口
- 尽量不污染每个 repo

默认分工：
- OpenCode = 主写手
- Codex = 冷审
- Hermes = research / memory / skills 外环
- Claude Code = 手动备用，不进 v1 热路径

默认工作流：
1. 小改动：`ai-build`
2. 正常开发：`ai-build` -> `ai-review`
3. 需要外部研究：`ai-research` -> `ai-build` -> `ai-review`

原则：
- 默认单主代理，不做多 agent 接力写代码
- review finding 是 hypothesis，不是施工命令
- plan 只在复杂任务出现，默认直接 build
- 规则文件要短、硬、稳定
- repo 内只允许临时产物进入 `.ai/tmp/` 和 `.codex/tmp/`

## 项目结构

```text
agent-workflow-bootstrap/
  install.sh
  bootstrap.sh
  env/
    workflow.env.example
  lib/
    common.sh
  bin/
    ai-build
    ai-review
    ai-research
    ai-doctor
  templates/
    opencode/AGENTS.md
    codex/AGENTS.md
    codex/skills/repo-review/SKILL.md
    codex/skills/repo-brief/SKILL.md
    hermes/SOUL.md
    hermes/config.fragment.yaml
  verify/
    smoke.sh
```

## 安装

本地源码安装：

```bash
cd ~/codes/agent-workflow-bootstrap
./install.sh
```

GitHub 直接安装（仓库上线后可用）：

```bash
curl -fsSL https://raw.githubusercontent.com/vvkee/agent-workflow-bootstrap/main/install.sh | bash
# 或
curl -fsSL https://raw.githubusercontent.com/vvkee/agent-workflow-bootstrap/main/bootstrap.sh | bash
```

默认行为：
- 复制全局模板到用户目录
- 在 `~/.local/bin/` 下创建命令入口的符号链接
- 若 `ai-research` 已被现有命令占用，自动回退安装为 `ai-research-workflow`
- 在 `~/.config/agent-stack/workflow.env` 初始化共享 env 文件（若不存在）
- 默认不覆写已有文件
- 默认不改 Hermes 配置；如需自动补 `skills.external_dirs`，使用 `--patch-hermes-skills`

常用参数：

```bash
./install.sh --force
./install.sh --patch-hermes-skills
./install.sh --force --patch-hermes-skills
```

## 四个命令

### `ai-build`
- 运行 OpenCode `build` agent
- 让 OpenCode 自己读 repo、自主短计划、实现、验证
- 默认要求输出：改动文件 / 核心原因 / 验证结果 / 剩余风险

### `ai-review`
- 生成当前 repo 的 review diff
- 调 Codex 做只读审查
- 默认只接受高价值输出：`PASS | REQUEST_CHANGES`

### `ai-research`
- 调 Hermes 做外部资料研究
- 默认输出：facts / unknowns / risks / recommendation

### `ai-doctor`
- 检查命令、全局模板、共享 env、repo 状态、临时目录

## 共享环境变量

安装后会生成：
- `~/.config/agent-stack/workflow.env`

默认变量见：
- `env/workflow.env.example`

重点变量：
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

- 本机当前未安装 `opencode`、`codex`，所以 `ai-build` / `ai-review` 目前只能完成脚本级验证，不能做真实集成测试
- `ai-review` 默认审查当前工作区 diff；若工作区干净，则回退审查最近一个 commit diff
- `ai-research` 默认使用 Hermes CLI；如配置了专门 profile，可在 `workflow.env` 中指定
- v1 不实现自动 review loop、自动 apply-review、Claude fallback 编排

## 推荐下一步

1. 安装 OpenCode / Codex
2. 跑 `ai-doctor`
3. 在一个测试 repo 里试：
   - `ai-build "修复一个小 bug"`
   - `ai-review`
   - `ai-research "调研某个库的最佳实践"`
