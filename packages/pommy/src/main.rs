//! Run an interactive Pomodoro timer and log only completed sessions.
mod config;
mod input;
mod journal;
mod ui;

use crossterm::event::{self, Event, KeyCode, KeyEventKind, KeyModifiers};
use ratatui::DefaultTerminal;
use std::{
    io,
    time::{Duration, Instant},
};

/// Load settings, collect a session, and report its logging outcome.
fn main() -> io::Result<()> {
    let directory = config::notes_dir()?;
    let path = journal::today(&directory);
    journal::validate(&path)
        .map_err(|error| io::Error::new(error.kind(), format!("{}: {error}", path.display())))?;
    let mut terminal = ratatui::init();
    let outcome = session(&mut terminal);
    ratatui::restore();
    let Some((message, minutes)) = outcome? else {
        println!("Cancelled.");
        return Ok(());
    };
    notify_completion(&message, minutes);
    let path = journal::today(&directory);
    journal::append(&path, &message, minutes).map_err(|error| {
        io::Error::new(error.kind(), format!(
            "Session completed but could not be saved to {}: {error}\nSession: {message} — {minutes} minutes",
            path.display()
        ))
    })?;
    println!("Session saved.");
    Ok(())
}

/// Announce completion without allowing a notification failure to prevent logging.
fn notify_completion(message: &str, minutes: u64) {
    let result = std::process::Command::new("notify-send")
        .args([
            "--app-name=Pommy",
            "--",
            "Pomodoro complete",
            &format!("{message} — {minutes} minutes"),
        ])
        .status();
    match result {
        Ok(status) if status.success() => {}
        Ok(status) => eprintln!("Desktop notification failed: {status}"),
        Err(error) => eprintln!("Could not send desktop notification: {error}"),
    }
}

/// Collect inputs and return only a completed session for logging.
fn session(terminal: &mut DefaultTerminal) -> io::Result<Option<(String, u64)>> {
    let Some((message, minutes)) = input::collect(terminal)? else {
        return Ok(None);
    };
    if run(terminal, session_duration(minutes)?)? {
        Ok(Some((message, minutes)))
    } else {
        Ok(None)
    }
}

/// Reject zero and durations that overflow when converted to seconds.
fn session_duration(minutes: u64) -> io::Result<Duration> {
    minutes
        .checked_mul(60)
        .filter(|seconds| *seconds > 0)
        .map(Duration::from_secs)
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "Invalid session duration"))
}

/// Update the countdown until it completes or the user cancels.
fn run(terminal: &mut DefaultTerminal, duration: Duration) -> io::Result<bool> {
    let start = Instant::now();
    loop {
        let remaining = duration.saturating_sub(start.elapsed());
        let ratio = (remaining.as_secs_f64() / duration.as_secs_f64()).clamp(0.0, 1.0);
        terminal.draw(|frame| ui::countdown(frame, remaining, ratio))?;
        if remaining.is_zero() {
            return Ok(true);
        }
        if event::poll(Duration::from_millis(100))?
            && let Event::Key(key) = event::read()?
        {
            let cancel = matches!(key.code, KeyCode::Char('q') | KeyCode::Esc)
                || (key.code == KeyCode::Char('c')
                    && key.modifiers.contains(KeyModifiers::CONTROL));
            if key.kind == KeyEventKind::Press && cancel {
                return Ok(false);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Valid minute values convert exactly and invalid durations never start.
    #[test]
    fn validates_duration() {
        assert_eq!(session_duration(25).unwrap(), Duration::from_mins(25));
        assert!(session_duration(0).is_err());
        assert!(session_duration(u64::MAX).is_err());
    }
}
