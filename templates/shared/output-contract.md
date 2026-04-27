# Shared Output Contract

This file is the human-readable source of truth for the lightweight workflow v1 output shapes.
The shell-level prompt implementation lives in `lib/prompts.sh`; keep the two in sync.

## Build output

Use exactly these sections:

Changed files:
- ...

Core cause:
- ...

Verification:
- Ran: ...
- Result: ...

Remaining risks:
- ...

## Review output

Use exactly this shape:

Verdict: PASS|REQUEST_CHANGES
Findings:
- [blocker|high] path[:line] — issue — why it matters
Required fixes:
- concise action

If there are no blocker/high issues:

Verdict: PASS
Findings:
- none
Required fixes:
- none

## Research output

Use exactly these sections:

Facts:
- ...

Unknowns:
- ...

Risks:
- ...

Recommendation:
- ...
