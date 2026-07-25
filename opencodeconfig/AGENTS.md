## Conversation Guidelines

- Keep answers concise and simple.
- Do not use emojis.
- Say what you changed and why.
- Be precise about uncertainty.
- Ask when requirements or project patterns are unclear.

## Core Workflow

### 1. Read Before Writing

Before changing code:

- Read the files you are about to touch.
- Check nearby patterns, imports, naming, and project conventions.
- Prefer existing project style over introducing a new style.
- Do not guess how the codebase works.

### 2. Think Before Coding

Before implementing:

- State the intended approach for non-trivial changes.
- Name assumptions and tradeoffs.
- Define what success looks like.
- Ask instead of filling gaps with plausible code.

### 3. Make Surgical Changes

- Keep diffs as small as the task allows.
- Do not touch unrelated code.
- Do not reformat unrelated files.
- Every changed line should be justified by the task.
- Avoid “while I was here” changes.

## Coding Guidelines

### Simplicity

- Write the minimum code needed to solve the current problem.
- Do not overbuild for hypothetical future requirements.
- Avoid premature abstraction.
- Hardcode values until there is a real reason to configure them.
- Prefer straightforward code over clever code.

### Structure

- Avoid deep nesting.
- If nesting becomes excessive, extract helper functions.
- Avoid large functions.
- Functions should stay under 50 lines unless necessary.
- Avoid large files.
- Files should stay under 250 lines unless the project requires otherwise.
- Follow the single responsibility principle.
- Each class, function, and module should have one clear job.

### Code Style

- Prefer small, immutable, deterministic functions.
- Minimize shared mutable state.
- Prefer intermediary variables when they improve readability.
- Keep code highly cohesive, loosely coupled, and composable.
- Avoid unnecessary guard checks.
- Use guard checks only when they protect meaningful failure cases.
- Do not hide real bugs with defensive code.

### Documentation

- Every module, function, and class should have a short docstring.
- Docstrings should explain purpose, not restate implementation.
- Keep docstrings self-contained when practical.
- Do not write long or noisy documentation.

## Verification

- Test behavior that can actually break.
- When fixing a bug, reproduce it before changing code.
- Prefer writing a failing test first, then make it pass.
- Do not claim something works without checking it.
- If something is hard to test, mention that as a design concern.

## Debugging

- Investigate before changing code.
- Read the full error and stack trace.
- Reproduce the problem first.
- Change one thing at a time.
- Do not paper over unexpected `null`, `undefined`, or invalid state.
- Find the cause, not just the symptom.

## Dependencies

- Avoid adding dependencies unless necessary.
- Prefer the standard library or existing project dependencies.
- Every new dependency must have a clear reason.
- Do not add packages for small utilities that can be written simply.

## Common Failure Modes

Avoid these patterns:

- **Kitchen Sink**: changing unrelated parts of the codebase.
- **Wrong Abstraction**: abstracting before duplication proves the need.
- **Optimistic Path**: handling only the happy path.
- **Runaway Refactor**: letting a small fix expand across many files.
- **Plausible Guessing**: writing code that looks right without verifying it.

When one of these appears, stop and narrow the change.

