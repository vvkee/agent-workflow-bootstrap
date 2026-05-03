# agent-workflow-bootstrap roadmap

Last updated: 2026-05-03 CST
Status: v1.1 stabilization / dogfood

## 0. North star

agent-workflow-bootstrap is a lightweight, portable bootstrap kit for a disciplined AI coding workflow.

It should give a fresh machine or fresh user:

- one repository
- one install entrypoint
- one shared env contract
- one small context protocol
- five stable command wrappers
- one clear role split across coding agents
- deterministic verification before trust

The project is intentionally not a heavy autonomous-agent platform. Its value is to make the safe path easy:

```text
human intent -> small context bundle -> one main writer -> deterministic checks -> clean-context reviewer -> human decision
```

## 1. Product definition

### What this repo is

A shell-first distribution that installs and wires together:

- `ai-build` — primary implementation entrypoint
- `ai-context` — context bundle / privacy boundary layer
- `ai-review` — clean-context Codex review entrypoint
- `ai-research` — Hermes research / facts / risk memo entrypoint
- `ai-doctor` — environment, config, and repo sanity checks

It owns generic workflow contracts, not user memory.

### What this repo is not

It is not:

- a personal knowledge base
- a multi-agent swarm runtime
- a replacement for project-specific tests or CI
- a place to store secrets, company source, private vaults, or raw chat archives
- a system that lets multiple agents write the same files in parallel by default
- a rewrite of Hermes, Claude Code, OpenCode, or Codex internals

## 2. Stable role architecture

Default role split:

| Role | Default tool | Responsibility | Write access |
|---|---|---|---|
| Human owner | vvkee / maintainer | goal, scope, final judgment, merge | yes |
| Primary writer | Claude Code | inspect repo, implement, verify, summarize | yes, one writer at a time |
| Alternate writer | OpenCode | optional main writer via `AGENT_BUILD_DRIVER=opencode` | yes, only when selected |
| Clean reviewer | Codex | review diff/scope, produce PASS or REQUEST_CHANGES | no |
| Research outer loop | Hermes | external docs, issues, release notes, risk memo | no repo mutation by default |
| Context boundary | `ai-context` | build small target-specific context bundles and check privacy/size | no source mutation |

Core rule:

```text
single writer, multiple readers/reviewers
```

Review findings are hypotheses. They do not become work items until a human or primary writer classifies them as confirmed.

## 3. Current baseline

Already present in the repo:

- `install.sh` with local install and GitHub self-bootstrap path
- `bootstrap.sh` as explicit remote bootstrap entrypoint
- global templates for Claude, OpenCode, Codex, Hermes, shared output contract, and context protocol
- shared env example at `env/workflow.env.example`
- command wrappers:
  - `bin/ai-build`
  - `bin/ai-context`
  - `bin/ai-review`
  - `bin/ai-research`
  - `bin/ai-doctor`
- shared shell libraries:
  - `lib/common.sh`
  - `lib/context_common.sh`
  - `lib/prompts.sh`
- verification assets:
  - `verify/smoke.sh`
  - `verify/test-install.sh`
  - `verify/e2e.sh`
  - fake CLI fixtures
- project docs:
  - `README.md`
  - `docs/roadmap.md`
  - `docs/architecture.md`
  - `docs/architecture.excalidraw`
  - `docs/company-workflow.md`

Important current design facts:

- v1.1 scope has expanded from four commands to five because `ai-context` is now a first-class boundary layer.
- `workflow.env` must behave as defaults; shell-provided env overrides must win.
- repo-local generated artifacts stay under `.ai/tmp/` or `.codex/tmp/`.
- direct GitHub install must stage the repo under a stable local directory, not a disposable temp directory.
- inactive executors should be informational in doctor output, not noisy blockers.

## 4. Roadmap stages

### Stage A — v1.0 foundation: done

Goal: prove the shell-only workflow shape.

Delivered:

- repository skeleton
- install script
- basic global templates
- basic `ai-build`, `ai-review`, `ai-research`, `ai-doctor`
- Claude-first default split
- Codex review-only contract
- Hermes research contract

Exit signal:

- local repo can install wrappers and run basic smoke checks.

### Stage B — v1.1 release stabilization: current

Goal: make the MVP installable, explainable, verifiable, and dogfood-ready.

#### v1.1 in scope

1. Documentation alignment
   - README reflects actual command set and install behavior.
   - Roadmap describes v1.1 through v2+ without over-scoping.
   - Architecture doc and editable architecture diagram are stored in `docs/`.
   - Company workflow is documented as policy guidance, not default personal workflow.

2. Installer hardening
   - `install.sh` is idempotent.
   - existing user files are not overwritten unless `--force` is passed.
   - command name collisions are handled safely.
   - GitHub direct install stages repo into a stable directory.
   - required local-file guard covers every template/file needed by installer.

3. Env contract hardening
   - `workflow.env` supports shell-compatible syntax.
   - shell overrides beat file defaults.
   - env loading preserves only known workflow keys and does not replay the full inherited env.
   - `AGENT_BUILD_DRIVER=opencode ai-build ...` works even if file default says `claude`.

4. Runtime wrapper contracts
   - `ai-build` supports `--driver`, `--model`, `--no-auto-approve`, `--dump-prompt`.
   - `ai-review` supports working-tree / last-commit review, `--model`, explicit untracked include, and prompt dump.
   - `ai-research` supports `--profile`, `--toolsets`, and prompt dump.
   - `ai-context` supports `init`, `bundle`, `review`, and `archive`.
   - all wrappers produce small, predictable prompts from shared prompt builders.

5. Context boundary
   - context templates install to `~/.config/agent-stack/context/`.
   - generated bundles are target-specific: builder, claude, opencode, reviewer, codex, researcher, hermes.
   - context review checks size and obvious secret-looking text.
   - context bundle is an operating contract, not a user memory store.

6. Verification
   - smoke test covers required files, syntax, env precedence, context, and wrappers.
   - temp-HOME install test proves fresh-machine behavior.
   - fake CLI e2e test proves wrapper prompt and command routing without paid APIs.
   - docs do not claim behavior that tests cannot support.

#### v1.1 release criteria

v1.1 is done only when all are true:

1. `bash verify/smoke.sh` passes.
2. `bash verify/test-install.sh` passes.
3. `bash verify/e2e.sh` passes.
4. `python3 -m json.tool docs/architecture.excalidraw >/dev/null` passes.
5. README, roadmap, architecture doc, and install targets agree.
6. `ai-context review` passes after a normal install.
7. The repo has been dogfooded once on itself:
   - `ai-context bundle --target claude --write`
   - `ai-build --dump-prompt "small doc/script change"`
   - `ai-review --dump-prompt`
8. No default repo-local artifacts outside `.ai/tmp/` or `.codex/tmp/`.
9. No secrets or personal/private memory are added to templates or docs.

#### v1.1 explicit non-goals

v1.1 will not ship:

- `ai-apply-review`
- automatic review loops
- automatic multi-agent orchestration
- persistent task database
- project-specific memory ingestion
- company-mode enforcement beyond documentation
- Hermes source-code modifications

### Stage C — v1.2 context and review hardening

Goal: make the boundary layer and review layer reliable enough for repeated real use.

Planned work:

1. Improve context review
   - stronger secret-looking pattern checks
   - optional internal URL / private path warnings
   - bundle line/byte summaries
   - clearer remediation messages

2. Improve target bundles
   - ensure builder bundles emphasize write-scope and verification
   - ensure reviewer bundles emphasize diff-only, no file mutation, and high-signal findings
   - ensure researcher bundles emphasize external-source evidence and no implementation

3. Improve `ai-review`
   - richer metadata for review scope
   - safer untracked-file inclusion rules
   - better fallback messaging when no diff exists
   - documented classification flow: confirmed / disproven / unclear / stale

4. Improve `ai-doctor`
   - active driver smoke as warning-worthy
   - inactive driver checks as info only
   - optional OpenCode provider/model smoke before recommending OpenCode as GPT writer
   - Codex command resolution diagnostics

5. Add docs/examples
   - one small feature example
   - one docs-only example
   - one review-only example

Exit criteria:

- A new user can understand why context bundle exists and how to safely review/fix Codex findings.
- `ai-review` can be used repeatedly without producing root-level review files or prompt clutter.

### Stage D — v1.3 work-safe / company profile

Goal: turn `docs/company-workflow.md` into an optional fail-closed profile shape.

Planned work:

1. Add a company profile template
   - approved endpoints only
   - no personal API fallback
   - no personal memory
   - stricter context limits
   - no network by default

2. Add company-mode checks
   - fail if personal provider keys are selected
   - warn on secret-looking context
   - warn on internal-url-looking context if policy says public-docs-only
   - make driver approval explicit

3. Add worktree/branch guidance
   - one feature branch/worktree per AI task
   - no multi-agent writes to same files
   - deterministic verification before PR

4. Add policy docs
   - what belongs in PR descriptions
   - what not to put in prompts
   - how to separate personal and company profiles

Exit criteria:

- Company mode can fail closed before sending code or context to an unapproved tool.
- The default personal workflow remains lightweight and is not burdened by company-only complexity.

### Stage E — v1.4 distribution and release quality

Goal: make releases boring.

Planned work:

- add versioned release notes
- add CI or local release checklist for shell scripts and docs
- add shell syntax checks across `bin/`, `lib/`, `verify/`, and installer scripts
- add install tests for macOS and Linux assumptions where practical
- add changelog and compatibility notes for CLI flag drift
- add a minimal support/troubleshooting doc

Exit criteria:

- A tagged release can be installed by raw GitHub script and verified in temp HOME.
- Troubleshooting common failures does not require reading source.

### Stage F — v2.0 controlled review-apply loop

Goal: add review-loop leverage without turning the project into an autonomous swarm.

Candidate features:

- `ai-apply-review`
- classification-first review handling:
  - confirmed
  - disproven
  - unclear
  - stale
- primary writer fixes only confirmed findings
- optional second `ai-review` pass after fixes
- loop limit defaults to one apply pass
- no automatic merge/push/deploy

Exit criteria:

- apply-review reduces repeated manual friction while preserving single-writer control.
- false-positive review findings do not automatically mutate code.

### Stage G — v2.x adapters and examples

Goal: make the workflow portable across real projects without repo pollution.

Candidate work:

- example profiles for:
  - personal solo project
  - docs-only repo
  - frontend app
  - CLI tool
  - company-safe workflow
- optional MCP/profile hooks documented but not required
- multi-repo dogfood examples
- driver-specific troubleshooting:
  - Claude Code
  - OpenCode
  - Codex
  - Hermes

Exit criteria:

- Users can adopt the workflow by choosing a profile and editing a small context file, not by copying long prompts.

### Stage H — v3.0 optional orchestration boundary

Only consider this if v1/v2 dogfood proves the wrappers are stable.

Possible direction:

- a thin orchestration command that sequences existing wrappers
- strict human confirmation gates between phases
- no background autonomous mutation by default
- no parallel writes to the same repo

Do not start v3 until there is clear evidence that wrappers, context discipline, and review classification are stable in repeated real use.

## 5. Prioritized backlog

### P0 — finish current doc and release alignment

- [x] write complete roadmap
- [x] write architecture document
- [x] add editable architecture diagram
- [x] update README links to architecture artifacts
- [x] run release verification commands
- [x] resolve doc/code mismatch found by verification

### P1 — harden v1.1 release gates

- [ ] verify `install.sh` raw GitHub path from a temp HOME
- [ ] verify command symlink collision handling
- [ ] verify env override precedence in smoke tests
- [ ] verify fake CLI e2e for Claude and OpenCode driver paths
- [ ] verify Codex review wrapper prompt dump path
- [ ] verify context bundle generation for all targets

### P2 — improve context safety

- [ ] stronger secret-looking checks
- [ ] internal-url-looking warnings for company profile
- [ ] better context review summary
- [ ] documented context file line/byte budgeting

### P3 — improve reviewer workflow

- [ ] review finding classification template
- [ ] `ai-apply-review` design doc before implementation
- [ ] one dogfood sample showing PASS
- [ ] one dogfood sample showing REQUEST_CHANGES and confirmed/disproven classification

### P4 — optional driver expansion

- [ ] OpenCode provider/model smoke in `ai-doctor`
- [ ] experimental `AGENT_BUILD_DRIVER=codex` design note
- [ ] only implement Codex build driver if real dogfood justifies it

## 6. Decision log

### D-001: Claude-first, single-writer default

Decision: Claude Code remains the default primary writer.

Reason:

- daily coding benefits from continuous writer context
- this aligns with current repo templates and user workflow preference
- alternate writer selection remains possible via `AGENT_BUILD_DRIVER`

### D-002: Codex is reviewer by default

Decision: Codex remains clean-context reviewer, not default co-writer.

Reason:

- clean reviewer context catches different issues
- review findings should be evidence-backed hypotheses
- separating write and review reduces context rot and role confusion

### D-003: OpenCode is optional alternate writer

Decision: OpenCode remains available behind driver switch.

Reason:

- OpenCode is valuable as provider-agnostic harness
- it should not become default until provider/model smoke and agent permissions are tuned
- inactive drivers should not make doctor noisy

### D-004: Context bundle is not memory

Decision: `ai-context` manages a small operating contract, not durable user memory.

Reason:

- real long-term memory belongs outside this bootstrap kit
- prompt/context bloat reduces agent reliability
- private data must not be bundled by default

### D-005: Shell wrappers over platform rewrite

Decision: keep v1 shell-first.

Reason:

- shell wrappers are inspectable, portable, and easy to install
- tool internals change; wrappers can normalize behavior without owning the world
- a heavy platform would slow the project before the workflow is proven

### D-006: Company workflow must fail closed

Decision: any future company profile must stop if approved drivers/endpoints are not configured.

Reason:

- silently falling back to personal API keys or personal memory is unacceptable for company code
- policy failure should happen before prompts are sent

## 7. Risk map

| Risk | Impact | Mitigation |
|---|---:|---|
| CLI flag drift in Claude/OpenCode/Codex | high | smoke/e2e fixtures, release checklist, small wrappers |
| context/prompt bloat | high | line/byte limits, target bundles, short templates |
| review findings treated as commands | high | strict reviewer output, classification before fix |
| personal memory or secrets leak into bundles | high | context review, privacy templates, no real memory in repo |
| install script clobbers user config | high | default no overwrite, `--force` explicit, collision fallback |
| OpenCode model/provider not configured | medium | doctor smoke before recommendation, keep optional |
| docs drift from implementation | medium | docs are part of release criteria |
| project expands into heavy platform too early | medium | explicit non-goals, stage gates |

## 8. Operating cadence

Recommended cadence while v1.1 is unstable:

1. make the smallest wrapper/doc change
2. run the smallest relevant verification
3. run full release checks before tagging
4. dogfood on this repo
5. document only durable decisions, not every temporary experiment

Do not add a new command, profile, or abstraction unless it removes repeated friction observed at least twice.

## 9. Research note: Codex vs OpenCode as GPT-5.5 writer (2026-05-01)

This research note is preserved because it affects future driver decisions.

Scope reviewed for the project decision:

- X / community discussions
- Reddit `r/codex` and `r/opencodeCLI`
- Codex official docs
- OpenCode official docs / GitHub README
- current local smoke-test reality for Codex and OpenCode

Conclusion for this project, not a universal tool ranking:

- If forced to choose between `Codex + GPT-5.5` and `OpenCode + GPT-5.5` as a default OpenAI-model writer for ordinary users today, prefer `Codex + GPT-5.5`.
- OpenCode's value is not that it is automatically a better writer with the same model. Its value is provider-agnostic harness control: custom agents/subagents, permissions, LSP, model routing, and context isolation.
- OpenCode should stay a power-user / optional harness until provider/model smoke passes and agent permissions are tuned.
- Codex official docs position Codex CLI as a local coding agent with AGENTS.md, review, local code inspection, subagents, skills, MCP, and automation; as an OpenAI-native harness it is currently lower-friction.
- Multi-agent experience still points to single writer plus clean reviewer/search/smart-friend, not parallel writers mutating the same repo.

Project decision:

- v1.1 does not change the default split: `Claude Code = default writer`, `OpenCode = alternate writer`, `Codex = reviewer`.
- If the project later adds an OpenAI-only build driver, prefer an experimental `AGENT_BUILD_DRIVER=codex` path before promoting `OpenCode + GPT-5.5` as default.
- OpenCode remains `AGENT_BUILD_DRIVER=opencode`, but `ai-doctor` should eventually add provider/model smoke before recommending it as a GPT-5.5 writer.
- Docs must keep saying that Codex review findings are hypotheses. Future apply-review must classify findings as confirmed / disproven / unclear / stale before code is changed.

## 10. Final shape for first public-quality release

A user should be able to run:

```bash
curl -fsSL https://raw.githubusercontent.com/vvkee/agent-workflow-bootstrap/main/install.sh | bash
ai-doctor
ai-context review
ai-build "make a small safe change"
ai-review
```

And understand from docs:

- which tool writes
- which tool reviews
- where context comes from
- where temporary artifacts go
- what is intentionally not automated
- how to verify the setup
