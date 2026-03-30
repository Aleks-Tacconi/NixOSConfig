---
description: Generate an AGENTS.md file corresponding to the project
agent: build
model: openai/gpt-5.4
---

Gather information about this repository and generate + populate an AGENTS.md file using the following template. Only insert values between the provided insertion boxes represented as such `[INSERT]`

```md
# \[INSERT HERE\]

## Guidelines

- Update this file when you find / change anything that would conflict with the knowledge in this file (`./AGENTS.md`)
- Try to keep files to under 200 lines of code, if file exceeds 200 lines separate it into modules where it makes sense
\[INSERT HERE\]

## Tech stack and frameworks

\[INSERT HERE\]

## Repository layout and structure

\[INSERT HERE\]

## Build / Lint / Test commands

\[INSERT HERE\]

## Design language

\[INSERT HERE\]

## Documentation links

- Looks for skills `./.agents/skills` that match your task before making any decisions
- You can use webfetch to access the following documentations to look for implementation details
  \[INSERT HERE\]

## Pre hand-off instructions

- Always verify lint, build, and test commands show no errors before handing changes off to a user
```

## Important

- Keep the `Repository layout and structure` section very high level
  - Keep it to modules only, not files
  - However, also include anything else that's important. E.g. 
    - Entry points
    - Dependency files `package.json`, `pyproject.toml`
    - Dockerfiles
    - README's / Other locations containing documentation
- Only add the `Design language` section if applicable. E.g. backend micro services do not need a design language section
  - Only pre-fill the design language section if design language is present. E.g. application already uses a set color scheme.
