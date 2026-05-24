# The harness-tuner philosophy

harness-tuner is an opinionated Claude Code harness configuration. This document explains the opinion: what the five layers are, when each earns its place, and why the framework is composed the way it is. For installation and usage, see the README.

---

## The 5 layers of the Claude Code harness

Claude Code exposes five distinct extension points. Most projects use one or two. Understanding all five — and what each costs — is prerequisite to composing them well.

### Rules

Rules are markdown files loaded unconditionally at session start. Every token is injected into the agent's context window before the first user message, on every task, whether relevant or not.

Use rules for behavior that is genuinely universal — identity (role, language, permissions), memory protocol (how to call Engram), and a routing table (which skill handles which task type). Nearly everything else does not qualify.

Do not use rules for workflow-scoped conventions. Testing conventions only matter during TDD's refactor step; loading them at session start taxes requirements grilling, git operations, and architecture work for no benefit.

### Skills

Skills are markdown files loaded on demand. Claude Code reads only the skill name and description at startup; the full content is injected only when the skill is invoked. Skills are the right home for any behavior that is workflow-specific rather than universal.

Use skills for complete, self-contained workflows — SDD pipeline phases, code review, architecture evaluation, TDD cycles. Each skill can reference sub-documents pulled in only at invocation time. Do not use skills for behaviors that must trigger automatically on lifecycle events; that is what hooks are for.

### Hooks

Hooks are scripts registered to Claude Code lifecycle events: before a tool call, after a tool call, at session start, at session stop. Hooks run outside the agent's reasoning loop. They consume zero context window.

Use hooks for deterministic, repeatable work that requires no judgment: formatters, memory lifecycle calls, git guardrails. Do not use hooks for anything requiring the agent to reason — that belongs in skills or rules.

### MCP servers

MCP servers expose callable tools to the agent — memory lookup, documentation retrieval, external API access. Unlike rules and skills, MCP tools are not injected into context; the agent calls them explicitly and only their output enters the context window.

Use MCP servers for runtime capabilities invoked as needed: cross-session memory (Engram), up-to-date library docs (context7), external system queries. Do not use them as a substitute for rules; a tool that returns conventions on every call is just a rule the agent has to remember to invoke.

### Subagents

Claude Code's native Explore and Plan subagents run in isolated context windows. Work done inside does not touch the main session's context.

Use subagents for exploration that would otherwise consume a large share of the main context: reading many files, tracing call chains, building dependency graphs. Do not spin one up when a skill invoked from the main agent will do; the overhead is only justified when the alternative is flooding the main session with intermediate reasoning.

---

## Why minimal rules

Every token in a rule is loaded on every task. There is no conditional rule. Add one and you have added a permanent tax on every session — requirements gathering, bug fixes, git operations, casual questions, all of it.

The rule of thumb: a rule earns its place only if every task needs it. In practice that means three: identity (role, language, permissions), Engram protocol (memory persistence is load-bearing across every session), and the SDD router (a compact task-to-skill mapping). Testing conventions, code style, workflow checklists — these belong in the skills that use them, loaded on demand.

A minimal rule set leaves more context available for the actual work — headroom that matters on long architecture or multi-file sessions.

---

## Why hooks for mechanical work

Mechanical work requires no judgment. Run the formatter after an edit. Call `mem_context` at session start. Block a destructive git command before it executes. None of these require reasoning — they require execution.

When mechanical work runs as agent behavior, two things happen. It consumes context. And it can be skipped, because it depends on the agent remembering to do it.

Hooks eliminate both problems. A `PostToolUse` hook that detects the file extension and runs the correct formatter is deterministic, always fires, and contributes zero tokens to context. The four hooks in harness-tuner cover session memory load, session memory save, post-edit formatting, and git guardrails. They run silently and the agent's reasoning capacity is preserved for actual work.

---

## Why subagents for exploration

Exploration accumulates context fast. Reading many files, tracing call chains, building a dependency graph — all of this, done in the main agent's context, crowds out the rest of the session.

Subagents solve this by running exploration in a separate context window. The main agent delegates, receives a structured summary, and continues with its context largely intact. Skills in harness-tuner that involve broad codebase analysis invoke Claude Code's native Plan or Explore subagents with curated prompts; the intermediate work stays isolated, and a subagent starting clean is less likely to be skewed by earlier conversation turns.

---

## Why workspace-scoped

Global configuration — junctions in `~/.claude/`, shared skill directories, machine-level MCP registrations — creates hidden state. When something breaks, the first question is always: which global config applies? The answer requires reconstructing what was installed when, on which machine, for which project.

harness-tuner puts everything in `.claude/` inside the project workspace. Running `ht init` on a new project produces an identical harness regardless of machine state or prior versions.

Two consequences follow. Portability: a project bootstrapped on one machine works identically on another. Predictability: open a project, look at `.claude/`, and you see exactly what the agent will load — no hidden layer.

The only global touch is the `ht` shell alias in `$PROFILE`. That is a shell convenience, not configuration. Everything that affects agent behavior lives in the project.

---

## The bundle + opinion identity

harness-tuner is two things simultaneously.

As a bundle, it is a curated set of skills, hooks, MCP configuration, and minimal rules that work together coherently. Running `ht init` deploys all of it in one step: SDD pipeline, memory lifecycle automation, git guardrails, post-edit formatting, documentation lookup, and a skill router — already integrated.

As an opinion, it is this document. The opinion explains why the bundle is composed the way it is: three rules instead of eight, hooks for formatters instead of a skill, exploration delegated to subagents rather than run inline, no global installation. A bundle without an articulated opinion is a collection of files. The opinion is what makes it a framework.

Both halves are necessary. The bundle without the opinion gives you configuration you cannot adapt. The opinion without the bundle is advice without an implementation. Together they give you a starting point you can use immediately and modify confidently.

If you disagree with part of the opinion — a rule that genuinely applies to every task, a workflow that warrants a custom subagent — extend the bundle. The opinion is a starting position, stated clearly enough that you can diverge deliberately rather than by accident.
