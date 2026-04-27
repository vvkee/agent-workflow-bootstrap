# agent-workflow-bootstrap roadmap

## v1.1 goal

把当前 shell-only MVP 从“能本地跑”推进到“可安装、可验证、可 dogfood 的轻量 bootstrap”。

核心判断：
- 继续保持 claude-first、单主写手、冷审与外部研究分离
- 先把安装可靠性、命令契约、调试能力、验证链路做扎实
- 不把项目扩成重型 agent 平台

## In scope

v1.1 只做这些事：
- 统一 `ai-build` / `ai-review` / `ai-research` 的 prompt 与输出契约来源
- 给 wrapper 增加少量单次覆盖参数与 prompt 调试落盘能力
- 补 temp-HOME 安装验证
- 补 fake CLI fixtures 的 e2e 验证
- 明确 release gate
- 收口 README 与维护者文档
- 修正 GitHub 直接安装链路，使 bootstrap 落到稳定本地目录而不是临时解压目录

## Out of scope

v1.1 明确不做：
- `ai-apply-review`
- 自动 review loop
- 自动多 agent 编排
- repo 内大量计划文档或本地配置文件生成
- Hermes 源码改造
- 重型插件系统 / 平台化抽象

## Product shape

v1.1 目标产品仍然只有四个命令：
- `ai-build`
- `ai-review`
- `ai-research`
- `ai-doctor`

默认分工保持不变：
- Claude Code = 主写手默认值
- OpenCode = 备选主写手
- Codex = 冷审
- Hermes = 外部研究 / memory / skills 外环

## Release criteria

满足以下条件才允许视为 v1.1 完成：
1. `bash verify/smoke.sh` 全通过
2. temp-HOME 安装验证通过
3. fake CLI e2e 验证通过
4. README 与当前代码行为一致
5. GitHub 直接安装会先把仓库落到稳定目录，再创建命令软链
6. 本机至少 dogfood 一次 `ai-build` / `ai-review` / `ai-research`

## Deferred after v1.1

只有在 v1.1 稳定之后，才考虑评估：
- `ai-apply-review`
- 更完整的 review loop
- 更强的 bootstrap doctor
- 真实多 repo dogfood 样本
- 更细粒度的 driver / model 策略
