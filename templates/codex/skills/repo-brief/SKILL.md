---
name: repo-brief
description: Turn a fuzzy implementation request into a light engineering brief. Use before coding when the task is ambiguous or high-risk.
---

# repo-brief

Use this skill to produce a light brief before implementation.

Output exactly these sections, in this order:
- Goal
- Why now
- Constraints
- Acceptance criteria
- Top risks
- Verification path

Shape rules:
- Keep each section to 1-3 bullets.
- Keep the whole brief short enough to guide implementation without replacing repo reading.
- Prefer concrete constraints and acceptance criteria over commentary.

Do not produce:
- detailed step-by-step implementation commands
- rigid file-by-file change scripts
- ordered implementation steps
- pseudo-diffs or patch instructions
- long architecture essays without decision value

The brief should make the task clearer without replacing the executor's own repo reading and planning.
