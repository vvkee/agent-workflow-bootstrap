# Company coding-agent workflow for vvkee

Date: 2026-05-01 14:35 CST

## Executive decision

For company work, the default goal is not maximum autonomy. The default goal is safe leverage inside corporate boundaries.

Recommended company workflow:

```text
Human owner / vvkee
  -> work-safe context pack
  -> one approved main writer
  -> deterministic local verification
  -> clean-context approved reviewer
  -> human PR ownership
  -> CI / team review / merge
```

Do not make a personal multi-agent swarm touch company repositories by default.

## Non-negotiable boundaries

1. Use only company-approved AI tools, accounts, endpoints, and gateways.
   - Do not paste private company source code, logs, designs, tickets, secrets, or internal URLs into personal ChatGPT, personal Claude, OpenRouter, personal API keys, Telegram bots, or personal Hermes memory.
   - If the company provides an internal LLM gateway or approved IDE/coding assistant, that is the default build driver.

2. Keep company code out of personal long-term memory.
   - No personal Obsidian/vault ingestion of company code.
   - No Hermes durable memory entries containing company implementation details.
   - No syncing company prompts/transcripts to personal machines or cloud note systems.

3. Keep execution local, scoped, and reviewable.
   - Start agents inside the repo or feature worktree only.
   - Deny reads for `.env`, secrets, credentials, cookies, tokens, private keys, and local config dumps.
   - Network access off by default unless the company has explicitly allowed it.
   - `git push`, deploy, package publish, prod config changes, database mutations, and destructive filesystem operations require human approval.

4. Treat AI output as draft code owned by vvkee.
   - Every AI change must be diff-reviewed by the human owner.
   - Every meaningful change must pass deterministic checks: typecheck, lint, unit tests, targeted e2e/storybook/snapshot checks, or a documented manual verification.
   - The PR is the audit artifact; not the chat transcript.

## Evidence from external research

### OpenAI / Codex docs

OpenAI Codex best practices emphasize:
- use clear task context: goal, context, constraints, done-when;
- store durable guidance in `AGENTS.md` instead of repeating long prompts;
- ask Codex to run tests, review diffs, and validate behavior;
- use `/review`, skills, MCP, automations only after workflows are stable;
- avoid one giant thread per project because bloated context reduces quality.

Codex security docs emphasize:
- default network access is off;
- local CLI/IDE uses OS-level sandboxing;
- workspace-write limits writes to the active workspace;
- approval policy controls actions outside sandbox, network access, and risky tools;
- `.env` and sensitive files can be denied via filesystem profiles;
- devcontainers can act as an outer isolation boundary;
- telemetry should keep prompt text redacted unless policy allows it.

### Anthropic / Claude Code docs

Claude Code security docs emphasize:
- read-only permissions by default;
- explicit approval for edits, tests, and shell commands;
- sandboxed bash and write-scope restriction;
- prompt injection protection, command blocklists, trust verification, and fail-closed behavior;
- sensitive repositories should use project-specific permission settings and dev containers;
- teams should use managed settings, shared approved permission configs, monitoring, and audit hooks.

Claude Code data docs emphasize:
- commercial users are not used for model training unless explicitly opted in;
- consumer Free/Pro/Max settings differ and must not be assumed safe for company code;
- `/feedback` can upload full conversation history including code and should be disabled or avoided for company code unless approved;
- local Claude Code stores plaintext transcripts under `~/.claude/projects/` by default for session resumption;
- telemetry/error reporting/feedback behavior depends on provider and env settings.

### OpenCode docs

OpenCode docs emphasize:
- provider-agnostic main agents and subagents;
- `build` for full development work, `plan` for analysis without code changes;
- `general` / `explore` style subagents can isolate context for research and code exploration;
- permissions can be `allow`, `ask`, or `deny` globally and per-agent;
- `.env` reads are denied by default, but most other permissions are permissive unless configured;
- external directory access should be explicitly allowed and limited.

### X / Reddit community signal

Repeated practical patterns:
- Treat `CLAUDE.md` / `AGENTS.md` / skills / commands as team infrastructure, not personal notes.
- Version prompts and skills like code. Review changes to them.
- Pairing/onboarding beats long docs; new users learn context calibration by watching.
- Team AI scaling bottleneck is coordination, not raw coding speed.
- PRs, tickets, CI, linters, type errors, and permission boundaries are stronger than “please follow this doc”.
- Multiple agents writing the same service causes git conflicts and deploy races. Serialize ownership or use worktrees.
- Governance is not just token tracking. Useful governance is RBAC, policy-as-code, audit trails, tool-call identity, secrets staying out of prompts, and data-plane controls.
- Cloud observability products that ingest prompts/transcripts are a security risk unless self-hosted/approved.

## Recommended company setup

### 1. Separate personal and company profiles

Use separate config roots on a company machine. Do not reuse personal agent memory or personal provider keys.

Suggested conceptual layout:

```text
~/.config/agent-stack-work/
  workflow.env
  context/
    company-boundary.md
    frontend-refactor-rules.md
    review-checklist.md
  bundles/
    current-task.md        # generated, short-lived, reviewed
```

Do not install personal Telegram/Hermes capture profiles into company work.

### 2. Company `workflow.env` contract

Use this as a policy shape, not necessarily exact shell today:

```bash
AGENT_ENV=company
AGENT_COMPANY_MODE=1
AGENT_POLICY=approved-endpoints-only

# Driver must point to a company-approved tool/provider.
AGENT_BUILD_DRIVER=approved
AGENT_REVIEW_DRIVER=approved-reviewer

# Disable accidental personal endpoints by default.
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
OPENROUTER_API_KEY=

AI_CONTEXT_ENABLED=1
AI_CONTEXT_MAX_LINES=180
AI_CONTEXT_MAX_BYTES=16000
AI_CONTEXT_ALLOW_PERSONAL_MEMORY=0
AI_CONTEXT_ALLOW_SECRETS=0
AI_CONTEXT_ALLOW_INTERNAL_URLS=0

# Research mode should use public docs only unless the company has approved internal access.
AI_RESEARCH_MODE=public-docs-only
```

Key principle: company mode must fail closed. If approved driver is not configured, the wrapper should stop instead of silently falling back to personal API keys.

### 3. Work-safe context pack

Before giving work to an agent, create a small context pack:

```text
Goal:
- What change should be made?

Scope:
- repo / package / files likely involved
- what not to touch

Constraints:
- company style conventions
- compatibility constraints
- performance / accessibility / i18n constraints
- no secret/internal URL exposure

Verification:
- exact test/build commands
- manual checks if no automated test exists

Done when:
- user-visible behavior
- CI expectation
- PR checklist
```

Do not include raw secrets, private incident logs, customer data, unreleased strategy docs, or broad file dumps.

### 4. Daily coding flow

#### Small task under 30 minutes

```text
1. Human writes short context pack.
2. Main writer makes minimal diff.
3. Human checks diff.
4. Run targeted verification.
5. PR or commit with clear summary.
```

No second agent required unless the area is risky.

#### Normal feature/refactor

```text
1. Create feature branch/worktree.
2. Ask agent for read-only analysis and affected-file map.
3. Human chooses one vertical slice.
4. Main writer implements only that slice.
5. Run local deterministic checks.
6. Clean-context reviewer reviews diff only.
7. Human classifies findings: confirmed / disproven / unclear / stale.
8. Fix confirmed findings.
9. PR with AI-assistance disclosure if team policy requires it.
```

#### High-risk migration / architecture change

```text
1. Human-owned RFC / ticket first.
2. Agent helps enumerate risk, blast radius, test matrix, rollout/rollback.
3. Break into multiple PRs by ownership boundary.
4. One writer per PR/worktree.
5. Reviewer agent only sees diff + minimal spec, not the whole coding transcript.
6. CI + team review are mandatory.
```

### 5. Large frontend refactor playbook

For vvkee’s company context, the highest ROI is large frontend refactor with safety rails.

Recommended loop:

```text
A. Baseline
- identify package/app boundary
- collect build/test commands
- list ownership and risky modules
- run current typecheck/lint/test once before changes

B. Slice
- choose one vertical slice: component, route, state module, API adapter, style system, or codemod target
- avoid cross-team files unless ticketed

C. Agent task
- ask for smallest safe diff
- forbid unrelated cleanup
- require migration notes and verification result

D. Verification
- typecheck
- lint
- targeted unit tests
- storybook/visual snapshot if UI changed
- e2e smoke if route behavior changed
- bundle/perf check if dependency or rendering path changed

E. Review
- clean-context diff review
- human check for product behavior, team conventions, rollout risk

F. PR
- concise PR description
- risk and rollback notes
- screenshots/video for UI changes
- link ticket/RFC
```

### 6. Permissions profile for company coding agents

Default posture:

```text
read source files: allow within repo
read .env / secrets: deny
edit source files: ask or allow only in workspace/worktree
bash: ask by default
safe read commands: allow
network: deny by default
git status/diff/log: allow
git commit: ask
git push: deny or ask
deploy/publish/prod ops: deny
external directories: deny unless explicitly approved
MCP/tool calls: ask unless company-approved and audited
```

Example safe command allowlist:

```text
git status*
git diff*
git log*
pnpm test*
pnpm lint*
pnpm typecheck*
npm test*
npm run lint*
npm run typecheck*
```

Example deny list:

```text
rm -rf *
curl * | sh
wget * | sh
cat *.env*
git push --force*
npm publish*
pnpm publish*
kubectl *
terraform apply*
```

### 7. Team adoption path

Start solo, then team, in three phases.

#### Phase 0: personal safe pilot, 1 week

Goal: prove productivity without violating policy.

- Use only approved tools.
- Work on low-risk slices.
- Keep a private checklist of what worked, not source code.
- Measure cycle time, bug count, review feedback, and reverted changes.

#### Phase 1: team infrastructure, 2-4 weeks

Goal: standardize the repeatable parts.

- Propose a short repo-level `AGENTS.md` / `CLAUDE.md` only if the team accepts it.
- Create team-owned review checklist and task template.
- Put prompts/commands/skills in a reviewed internal repo.
- Run pairing demos for teammates.
- Add deterministic CI gates before increasing autonomy.

#### Phase 2: governed automation

Goal: automate boring work, not risky decisions.

Good automation candidates:
- PR summary draft
- test plan draft
- migration checklist generation
- code review checklist against team conventions
- release note draft
- dependency impact analysis
- incident/log investigation through approved internal tools

Bad initial automation candidates:
- auto-merge
- prod deploy
- secret-bearing debugging
- cross-service migrations without owner review
- unrestricted web/MCP/tool access

## Recommended role split at work

```text
vvkee: product/architecture owner, risk owner, final PR owner
Main writer: one approved coding agent, continuous context for the current slice
Reviewer: clean-context approved reviewer, diff-only, no edits
Researcher: public docs / internal approved knowledge search only
CI: deterministic wall
Team review: final social/ownership gate
```

This matches both official docs and community experience: single writer, clean reviewer, strong deterministic gates.

## What agent-workflow-bootstrap should add later

After v1.1, consider a company-safe profile:

```text
bin/ai-work-doctor
bin/ai-work-context
bin/ai-work-build
bin/ai-work-review

templates/company/company-boundary.md
templates/company/frontend-refactor-checklist.md
templates/company/permissions.example.md
```

`ai-work-doctor` should check:
- current repo is git versioned;
- worktree or branch is not main;
- personal provider keys are not present or not used;
- company approved driver is configured;
- context bundle has no obvious secrets;
- `.env` and private-key patterns are denied;
- network is disabled by default;
- reviewer is configured only if approved;
- output goes to local temp dirs only.

Do not implement company mode as a default cloud sync feature. Company mode should be local-first, fail-closed, and policy-explicit.

## Bottom line

For company work, vvkee should become the person who makes AI coding safe and repeatable, not the person who secretly runs the most aggressive agent stack.

The winning posture is:

```text
approved tools only
small context packs
single writer
clean reviewer
deterministic checks
PR as audit trail
team-owned skills/templates
no company code in personal memory
```
