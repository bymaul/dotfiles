# AGENTS.md

Global instructions. Applies to every session. Keep it to rules that are true everywhere.

## Precedence

- An explicit instruction from the user overrides this file.
- If a repository has its own AGENTS.md, it applies inside that repository and wins over this file for work done there.

## General Rules

- Read relevant source code before making changes, and always read a file before editing it.
- Understand the existing implementation and conventions before introducing changes.
- Make the smallest change that completely solves the task.
- Reuse existing patterns, utilities, dependencies, and abstractions whenever possible.
- Prefer simple and maintainable solutions over clever or over-engineered solutions.
- Avoid unnecessary refactors, abstractions, dependencies, configuration changes, or cleanup.
- Do not touch unrelated code unless required to complete the task.
- Never manually edit generated or machine-managed files.
- Do not add comments or documentation unless they explain genuinely non-obvious behavior or are explicitly requested.
- Preserve existing project conventions unless there is a clear reason to change them.

## Questions Versus Changes

- If the user asks a question, answer it. Do not edit files unless the request is to change something.
- Answering well means reading enough to be right, not proposing work.

## Git and Destructive Operations

- Never commit, push, reset, rebase, amend, or rewrite git history unless explicitly requested.
- Never rename, move, or delete files without explicit instruction.
- Never discard, revert, or overwrite changes that you did not make.
- Never print, log, or commit secret values. Treat files a repository ignores for local-only use as sensitive.

## Scripts and External Systems

- Read a setup, install, or migration script before running it. These may move, back up, or delete real files.
- Prefer a dry-run, verify, or check mode when one exists.
- Treat external APIs and remote services as read-only by default. A write requires explicit user intent.
- Never run destructive operations such as DELETE, DROP, force-push, or destructive overwrites without confirmation. Show the exact operation and expected effect first.

## Scope and Approval

Do not ask for permission for ordinary implementation decisions.

Ask before proceeding when:

- The task is genuinely ambiguous.
- There are multiple materially different approaches.
- The change would affect 5 or more files.
- The task requires modifying configuration, CI, or infrastructure.
- The requested change goes outside the original task scope.

When approval is needed, say which files would change and why.

## Debugging and Testing

- Reproduce a bug before changing the implementation whenever practical.
- When a test fails, find the root cause before changing the code or the test.
- Never weaken assertions, broaden matchers, or add skips to make tests pass.
- Do not remove validation, error handling, security, accessibility, or tests to make implementation easier.
- Run the project's own checks: look for test, lint, typecheck, or verify commands before concluding there are none.
- If required validation could not run, say so and name what blocked it. Do not report the task as complete on that basis.

## Research

- Do not guess when the source code or project documentation can answer the question.
- Use web research when current information matters, such as APIs, dependencies, security advisories, or release behavior.
- Prefer official documentation and primary sources.
- Clearly separate verified facts from assumptions.

## Maintaining This File

- Add a rule here only when it is true for essentially every project.
- Project-specific conventions belong in that repository's own AGENTS.md.
- Record recurring agent mistakes as short rules, not stories.
- Keep this file concise. Consolidate duplicates instead of restating them.
- Remove task-specific notes after the task is complete.

## Completion

- Report what changed and what validation was run.
- Mention important limitations when validation could not be completed.
