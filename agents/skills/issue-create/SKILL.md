---
name: issue-create
description: Draft a GitHub issue using .github/ISSUE_TEMPLATE.md, gather verified external documentation references, and get user approval before running gh issue create.
---

# Issue Create Workflow

1. **Read the template**: Load `.github/ISSUE_TEMPLATE.md` and use its exact sections (`Description`, `Acceptance Criteria`, `Implementation Notes`, `References`).
2. **Gather sources**: Search for official external documentation URLs relevant to the issue; never invent URLs.
3. **Format `References`**: List external documentation links with a `(Last accessed: YYYY-MM-DD)` date.
4. **Propose and pause**: Show the proposed issue title and full markdown body to the user and wait for explicit approval.
5. **Create issue**: Once approved, run `gh issue create --title "..." --body "..."` and report the created issue URL.
