## General instructions

- Prefer small patches over large changes
- If a change is large break it up into multiple small patches

## Conversation Guidelines

- Make your answers as concise and simple as possible.
- Do NOT use emojis 

## Available Subagents

- The following is a description of available subagents and when to use them
  - context-gatherer: Use only when repository evidence is needed and missing. Keep the result structured and concise.
  - implementation-planner: Use after the request is clear to decide concrete next steps before proceeding with an implementation.
  - refactor-reviewer: Use for refactoring / optimisation tasks 

## Planning workflow

- Preferred sequence: Ask / clarify -> optional context-gatherer -> implementation-planner -> build
- Do not call context-gatherer by default. Use it when the answer or plan depends on verified repository behavior.
- Reuse previously gathered context in the same thread when it still matches the current scope. Re-run context-gatherer only when scope changed, context is incomplete, or the repository likely changed materially.

## Coding Guidelines

- Avoid deep layers of nesting when writing code, if nesting becomes excessive consider abstracting logic to a helper function
- Avoid large functions. Functions should not exceed 50 lines, unless necessary
- Avoid large files. Files should be kept under 250 lines unless otherwise specified in the project, or necessary
- SRP. Keep to the single responsibility principle, each class and function should have 1 job and 1 job only
- Prefer abstraction of logic into small immutable functions, write deterministic code and eliminate as much state from the code as possible
- Refrain from unnecessary guard checks, only employ guard checks on code when critical to do so
- Prefer the use of intermediary variables for code documentation
- Every module, function and class should contain docstrings. Keep these docstrings short and simple. Keep the docstrings self sustainable, If possible the docstrings should contain all the information needed to understand the purpose of the function without any other knowledge of the codebase (This will not be possible in some cases, that is fine). 
- All written code should be highly cohesive, loosely coupled, and composable so it remains modular and works well as a whole.
- Commit format: <type>: <description> — Types: feat, fix, refactor, docs, test, chore, perf, ci
- Always update README.md to stay aligned with any changes made, however DO NOT add sections to the README.md unless prompted to. Only modify present sections
- Use Context7 MCP to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service - even well-known ones. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer -- your training data may not reflect recent changes. Prefer this over web search for library docs. Fallback to web-search.
