---
description: Draft a document — postmortem, proposal, RFC, or any other type
---

Draft a document. This is an interactive process.

Arguments: `/draft <type> [title]`

Types: `postmortem`, `proposal`, `rfc` (or any freeform type).

1. Load `writing` skill.
2. Parse type from `$1`. If missing, ask with options: postmortem, proposal, RFC, other.
3. Identify the title (`$2`) and destination — where will this be published or shared? (e.g., "Engineering blog", "internal wiki", "team Slack"). Ask if not provided. Use the destination as `{{TARGET}}`.
4. Gather details based on type:
   - **postmortem** — date, summary, timeline, root cause, contributing factors, resolution, action items.
   - **proposal** — goal, background, proposed approach, success criteria, risks.
   - **rfc** — problem statement, proposed solution, alternatives considered, open questions.
   - **other** — ask the user for the document structure and key sections.
   Ask for missing values interactively.
5. Write to `drafts/<type>-<kebab-title>.md` in the current directory. Use the template at `~/.config/opencode/templates/draft-template.md` — replace `{{TARGET}}`, `{{DATE}}`, `{{TITLE}}`, and `{{CONTENT}}` with real values.
6. Load the `conventions` skill for the required commit message format. Commit.

$ARGUMENTS
