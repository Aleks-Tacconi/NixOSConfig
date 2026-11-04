# Pommy

A terminal Pomodoro timer that records completed sessions in daily Markdown notes.

Set the daily notes directory in Home Manager:

```nix
home.sessionVariables.POMMY_NOTES_DIR = "/home/aleks/ObsidianVault/04 DailyNotes";
```

Or set it in your shell:

```sh
export POMMY_NOTES_DIR="$HOME/ObsidianVault/04 DailyNotes"
```

Absolute paths and a leading `~/` are supported, including paths with spaces.
No config file is needed.

Run `pommy`, enter what you want to work on, then enter a positive whole number
of minutes. Use Tab to switch fields, Enter to advance/start, and Backspace to edit.
Leave minutes blank for 25 minutes. Ctrl+U clears the selected field. The countdown
shows minutes and seconds. A desktop notification announces completion. Press `q`, Escape, or Ctrl+C to cancel without logging.

The daily note must already exist and contain `## Pomodoro Sessions`. For example,
on November 1, 2026, Pommy uses `2026-11-01.md` in the configured directory:

```markdown
## Pomodoro Sessions
- 25 minutes - Write project proposal

## Other notes
```

Completed sessions are appended at the end of that section, before the next
level-one or level-two heading. Existing entries and other sections are preserved.
Pommy checks the note before starting and reads it again when saving. It never
creates a daily file or heading. The filename uses the local date at completion,
so a session crossing midnight requires the next day's file and heading as well.
If logging fails, Pommy prints the completed session and an error for manual recovery.
Avoid editing the note at the exact moment Pommy saves it; saving rewrites the file.

The Nix package includes `notify-send`. For development, make sure `notify-send`
(from `libnotify`) is on PATH and a desktop notification service is running.
Notification failures are reported without preventing the session from being logged.

Run during development from this directory:

```sh
cargo run
```

Check formatting, tests, and lint:

```sh
cargo fmt --check
cargo test
cargo clippy --all-targets -- -D warnings
```

Rebuild the NixOS configuration to install changes, then open a new shell
and run `pommy`. The shell alias points to the Nix-built executable.
