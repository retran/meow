---
name: conventions
description: Commit message and MR/PR title conventions — Jira key prefix for project repos, plain description for others
compatibility: opencode
---

# Commit & MR Title Conventions

The format depends on which repo you are working in.

**Project key:** Check the branch name or MR/PR title for the Jira key (e.g. `feature/PROJ-42-add-auth`). If not found there, check the MR/PR description or ask the user.

## By Repo Context

| Repo | Format | Example |
|------|--------|---------|
| **Project/code repo** | `[PROJ-123] description` | `[PROJ-42] add OAuth2 token refresh endpoint` |
| **Other repo** | `description` | `add address-review command` |

- **Project/code repos** — Jira key prefix is mandatory. No Conventional Commits type prefix.
- **Other repos** — plain description only. No Jira key, no type prefix.

## Full Format (project/code repo)

```
[PROJ-123] <short description>
```

- **`[PROJ-123]`** — Jira issue key in square brackets. Mandatory. Replace `PROJ` with the key from the branch name or MR title.
- **`short description`** — imperative, present tense, lowercase, no trailing period. Max ~72 chars total.

## Full Format (other repo)

```
<short description>
```

Plain imperative sentence describing what changed.

## Examples

**Project/code repo:**
```
[PROJ-42] add OAuth2 token refresh endpoint
[PROJ-99] handle null response from upstream service
[PROJ-7] upgrade eslint to v9
[PROJ-15] add edge cases for expired token handling
```

**Other repo:**
```
add address-review command
fix stale link in knowledge-graph
update context.md with new project
add weekly note for W14
```

## Rules

- **No Jira key in non-project commits.** Commits for non-project repos describe the change, not the task.
- **No Jira key = incomplete in project repos.** Every project commit and MR title must include `[PROJ-123]`.
- **No Conventional Commits type prefix** (`feat:`, `fix:`, etc.) in either repo.
- **Imperative mood.** "add", "fix", "remove" — not "added", "fixing", "removed".
- **One concern per commit.** Don't bundle a feature and a bug fix in a single commit.
- **MR title = the most important commit's message**, or a summary if the MR spans multiple logical changes.

## Finding the Jira Key (project repos)

If you don't know the Jira issue key:
1. Check the branch name — it often contains the key (e.g., `feature/PROJ-42-add-auth`)
2. Check the MR title or description
3. Ask the user — do not invent or omit the key
