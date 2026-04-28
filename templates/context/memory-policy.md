# Memory Policy

agent-workflow-bootstrap does not store a user's real long-term memory.
It only installs a small context protocol that other tools can consume.

## What belongs here

- Stable agent workflow rules.
- Output contracts.
- Privacy boundaries.
- Short project-neutral context needed by coding agents.

## What does not belong here

- Secrets or credentials.
- Personal financial records.
- Full private notes or vault exports.
- Raw chat logs.
- Large project documents copied wholesale.

## Update rule

Agents may suggest a context change, but they should not silently turn temporary observations into authoritative memory.
Prefer small reviewed diffs over automatic memory growth.
