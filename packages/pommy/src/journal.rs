//! Insert completed sessions into an existing daily Markdown section.
use chrono::Local;
use std::{
    fs,
    io::{self, Write},
    path::{Path, PathBuf},
};

/// Choose the note for the current local calendar date.
pub fn today(directory: &Path) -> PathBuf {
    directory.join(format!("{}.md", Local::now().format("%Y-%m-%d")))
}

/// Require the daily note and its Pomodoro section to exist.
pub fn validate(path: &Path) -> io::Result<()> {
    section_end(&fs::read_to_string(path)?)?;
    Ok(())
}

/// Append a completed session without creating a note or heading.
pub fn append(path: &Path, message: &str, minutes: u64) -> io::Result<()> {
    let source = fs::read_to_string(path)?;
    let updated = insert_session(&source, message, minutes)?;
    fs::OpenOptions::new()
        .write(true)
        .truncate(true)
        .open(path)?
        .write_all(updated.as_bytes())
}

/// Locate the end of the section, ignoring heading-like text inside code fences.
fn section_end(source: &str) -> io::Result<usize> {
    let mut found = false;
    let mut offset: usize = 0;
    let mut fence: Option<(char, usize)> = None;
    for line in source.split_inclusive('\n') {
        let text = line.trim();
        if let Some((marker, length)) = fence {
            if text.chars().all(|character| character == marker) && text.len() >= length {
                fence = None;
            }
        } else if text.starts_with("```") || text.starts_with("~~~") {
            let marker = if text.starts_with('`') { '`' } else { '~' };
            fence = Some((marker, text.chars().take_while(|c| *c == marker).count()));
        } else {
            let heading = text.trim_end_matches('#').trim_end();
            if found && (heading.starts_with("## ") || heading.starts_with("# ")) {
                return Ok(offset);
            }
            if heading == "## Pomodoro Sessions" {
                found = true;
            }
        }
        offset = offset.saturating_add(line.len());
    }
    if found {
        Ok(source.len())
    } else {
        Err(io::Error::other(
            "Daily note has no ## Pomodoro Sessions heading",
        ))
    }
}

/// Preserve surrounding content and append a Markdown bullet at the section's end.
fn insert_session(source: &str, message: &str, minutes: u64) -> io::Result<String> {
    let end = section_end(source)?;
    let (before, after) = source.split_at(end);
    let newline = if source.contains("\r\n") {
        "\r\n"
    } else {
        "\n"
    };
    let content = before.trim_end_matches(['\r', '\n']);
    let (_, spacing) = before.split_at(content.len());
    let spacing = if spacing.is_empty() { newline } else { spacing };
    let message = message.replace(['\r', '\n'], " ");
    Ok(format!(
        "{content}{newline}- {minutes} minutes - {message}{spacing}{after}"
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Existing entries, nested headings, and following sections survive insertion.
    #[test]
    fn inserts_before_next_section() {
        let source = "# Day\n\n## Pomodoro Sessions\n- Earlier — 10 minutes\n### Notes\nDetails\n\n## Tasks\n- Task\n";
        let result = insert_session(source, "Write résumé", 25).unwrap();
        assert!(result.starts_with("# Day\n\n## Pomodoro Sessions\n- Earlier — 10 minutes\n### Notes\nDetails\n- 25 minutes - Write résumé\n"));
        assert!(result.ends_with("## Tasks\n- Task\n"));
    }

    /// Missing headings are errors, including headings inside fenced code blocks.
    #[test]
    fn requires_real_heading() {
        assert!(insert_session("# Day\n", "Work", 25).is_err());
        assert!(insert_session("```md\n## Pomodoro Sessions\n```\n", "Work", 25).is_err());
    }

    /// EOF, Windows line endings, and code fences are supported.
    #[test]
    fn handles_section_boundaries() {
        assert!(
            insert_session("## Pomodoro Sessions", "Work", 25)
                .unwrap()
                .contains("\n- 25 minutes - Work\n")
        );
        let source = "## Pomodoro Sessions\r\n```\r\n## Example\r\n```\r\n## Next\r\n";
        let result = insert_session(source, "Work", 1).unwrap();
        assert!(result.contains("```\r\n- 1 minutes - Work\r\n"));
        assert!(result.ends_with("## Next\r\n"));
    }
}
