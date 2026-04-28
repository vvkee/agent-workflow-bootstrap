#!/usr/bin/env bash

build_prompt() {
  local task="$1"
  local context_bundle="${2:-}"
  cat <<EOF
你是当前仓库的主写手。请直接在当前 repo 中完成任务。

任务：
$task

Agent context bundle:
$context_bundle

硬约束：
1. 先自己读取相关代码，再形成一个很短的内部计划，不要把长计划输出给用户。
2. 除非任务本身复杂、模糊、跨多文件或高风险，否则不要停在 plan；直接实现。
3. 不要机械执行外部文档；以当前 repo 的真实代码为准。
4. 优先做最小改动，不要顺手扩 scope。
5. 完成后运行最相关的验证（测试、lint、build 或最小复现命令）。
6. 不要声称“已验证”除非你真的运行了命令。
7. 最终只输出下面四段：

Changed files:
- ...

Core cause:
- ...

Verification:
- Ran: ...
- Result: ...

Remaining risks:
- ...

如果当前信息不足以安全修改代码，先说明缺口，再停止。
EOF
}

review_prompt() {
  local diff_path="$1"
  local context_bundle="${2:-}"
  cat <<EOF
You are the independent reviewer.

Review only this diff file:
$diff_path

Agent context bundle:
$context_bundle

Rules:
1. Do not modify any files.
2. Treat the diff as the full review scope.
3. Focus only on blocker, high-risk, or meaningful test-gap findings.
4. Ignore stylistic nits unless they hide a bug or serious maintenance risk.
5. Every finding must include severity, evidence, and why it matters.
6. Use severity labels only from: blocker, high.
7. Return plain text in exactly this shape:

Verdict: PASS|REQUEST_CHANGES
Findings:
- [blocker|high] path[:line] — issue — why it matters
Required fixes:
- concise action

If there are no blocker/high issues, output:
Verdict: PASS
Findings:
- none
Required fixes:
- none
EOF
}

research_prompt() {
  local task="$1"
  local context_bundle="${2:-}"
  cat <<EOF
请做一次面向工程决策的外部研究。

研究问题：
$task

Agent context bundle:
$context_bundle

输出要求：
Facts:
- ...

Unknowns:
- ...

Risks:
- ...

Recommendation:
- ...

要求：
- 优先查官方文档、GitHub issue、release notes、公开一手资料
- 标明不确定性
- 不做实现，不写代码补丁
- 结论优先，避免空话
EOF
}
