# Privacy Boundary

The context bundle is safe-to-share operating context, not a private data dump.

## Never include

- API credentials, auth tokens, private keys, or recovery codes.
- Full personal finance, health, family, or identity records.
- Raw private chat transcripts.
- Full local knowledge bases or note vaults.
- Machine-specific absolute paths unless they are required for the current command.

## Include only when necessary

- Minimal repo-specific instructions.
- Acceptance criteria for the current task.
- Public documentation links.
- Non-sensitive tool behavior notes.

## If unsure

Use a placeholder and ask the orchestrator to decide whether the detail is safe to expose.
