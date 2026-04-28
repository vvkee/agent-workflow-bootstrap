# Agent Workflow Context Bundle Example

Target: codex
Source: ~/.config/agent-stack/context

## Target-specific instructions

Role: independent read-only reviewer.
Rules: review only the provided diff/scope. Do not modify files.

## Context discipline

- This bundle is a small operating contract, not a personal knowledge base.
- If this bundle conflicts with the current repository, trust the repository.
- Do not request or expose secrets, credentials, private records, or full personal vaults.

## agent-rules.md

Short role contract goes here.

## memory-policy.md

Memory governance goes here.

## privacy-boundary.md

Privacy and redaction rules go here.
