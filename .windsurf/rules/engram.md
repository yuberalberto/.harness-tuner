---
trigger: always_on
description: Engram memory protocol for Cascade
---
# Engram Memory Protocol

Save proactively after: architecture decisions, bugfixes, discovered gotchas, config changes.

## Format

- **What**: Concise description of what was done
- **Why**: Reasoning, user request, or problem that drove it
- **Where**: Files/paths affected
- **Learned**: Any gotchas, edge cases, or decisions made

## Runtime Protocol

- **Search**: Call `mem_search` before tasks that likely have prior decisions or patterns.
- **Upsert**: For evolving topics (architecture, backlog), use `topic_key` to avoid duplicates.
- **Scope**: Mark observations as `project` (default, codebase-scoped) or `personal` (cross-project learnings).
