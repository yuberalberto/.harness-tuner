## Session Start

Call `mem_context` (Engram) as your **first action** every session to restore prior state.

---

## Engram Memory Protocol

- **Session Start**: `mem_context` — first action, every session.
- **Save proactively** after: architecture decisions, bugfixes, discovered gotchas, config changes.
- **Format**: `**What**` / `**Why**` / `**Where**` / `**Learned**`
- **Upsert**: For evolving topics (architecture, backlog), use `topic_key` to avoid duplicates.
- **Search**: Call `mem_search` before tasks that likely have prior decisions or patterns.
- **Session End**: Call `mem_session_summary` with structured Goal/Discoveries/Accomplished/Files.
