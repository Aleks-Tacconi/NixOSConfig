---
name: commit
description: Audit changes with git diff, split them into logical commits, cross-check GitHub issues, and present planned commits for approval before committing.
---

# Commit Workflow

1. **Audit changes**: Run `git status` and `git diff` (including `git diff --cached` if anything is staged) to inspect all modifications.
2. **Split logically**: Group changes into minimal, single-purpose logical components.
3. **Check GitHub issues**: Run `gh issue list` to find an existing issue for each component.
   - If no related issue exists, ask the user whether to create one (following `.github/ISSUE_TEMPLATE.md` via `gh issue create`) or provide an issue number before proceeding.
4. **Format commit messages**:
   - Format: `<type>(<scope>): <simple explanation> (#<issue_num>)`
   - Never use conjunctions (`and`, `or`, `&`, `+`) in a commit message; split into separate commits instead.
   - Keep the message as simple as possible without sacrificing technical terminology.
   - Single-line subject only - no extended description/body.
5. **Propose and pause**: Print each planned commit message and its file scope, then pause for explicit user approval before running `git add` or `git commit`.
