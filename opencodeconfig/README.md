- Install plugins

```sh
go install github.com/edouard-claude/snip/cmd/snip@latest
```

- Custom OpenCode slash commands live in `commands/` and are also registered in `opencode.jsonc`.
- Primary agents are `build`, `plan`, `ask`, and `neovim`.
- Recommended planning flow is `ask -> optional context-gatherer -> implementation-planner -> build`.
- Use `/plan-feature` for a repeatable planning flow that clarifies first and gathers repo context only when needed.
- Prefer running `/plan-feature` once per feature, then continue follow-up planning in the same thread so existing gathered context can be reused.
- Agent prompts live in `prompts/` and are referenced from `opencode.jsonc`.
