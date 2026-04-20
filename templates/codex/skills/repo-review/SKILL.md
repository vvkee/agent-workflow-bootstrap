---
name: repo-review
description: Review a repo diff as an independent reviewer. Use for blocker issues, regression risks, and meaningful test gaps.
---

# repo-review

Use this skill when reviewing current code changes.

Output contract:
- Verdict: PASS or REQUEST_CHANGES
- Findings:
- Required fixes:

Rules:
- Review only the requested diff/scope.
- Focus on blocker, high-risk, and test-gap findings.
- Do not produce stylistic noise.
- Do not rewrite the implementation.
- Treat yourself as a second pair of eyes, not the project owner.
