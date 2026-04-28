# Agent Rules

This file defines the stable role contract installed by agent-workflow-bootstrap.
It is intentionally short and generic.

## Core workflow

1. Use one primary writer for code changes.
2. Use independent reviewers as read-only critics.
3. Use research agents for facts, APIs, release notes, and risks.
4. Treat review and research outputs as hypotheses until verified against the repo.
5. Keep repo-local temporary outputs under `.ai/tmp/` or `.codex/tmp/`.

## Role boundaries

- Builder: may edit code, but must inspect the repo and run verification.
- Reviewer: must not edit files; it should return only material findings.
- Researcher: must not mutate repo state; it should return facts, unknowns, risks, and recommendations.
- Orchestrator: chooses the path, narrows scope, and makes the final decision.

## Default refusal conditions

Stop and ask for a narrower scope when the task would require broad rewrites, unclear credentials, destructive operations, or private data exposure.
