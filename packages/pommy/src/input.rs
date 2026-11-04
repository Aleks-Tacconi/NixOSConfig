//! Collect a session using a compact keyboard-driven form.
use crate::{session_duration, ui};
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use ratatui::{
    DefaultTerminal, Frame,
    layout::{Constraint, Layout, Rect},
    style::{Color, Style, Stylize},
    widgets::{Block, BorderType, Paragraph},
};
use std::io;

/// Editable session fields and the current validation message.
#[derive(Default)]
struct Form {
    message: String,
    minutes: String,
    editing_minutes: bool,
    error: &'static str,
}

/// Collect a validated message and duration, or return cancellation.
pub fn collect(terminal: &mut DefaultTerminal) -> io::Result<Option<(String, u64)>> {
    let mut form = Form::default();
    loop {
        terminal.draw(|frame| draw(frame, &form))?;
        let Event::Key(key) = event::read()? else {
            continue;
        };
        if key.kind != KeyEventKind::Press {
            continue;
        }
        if key.code == KeyCode::Esc
            || (key.code == KeyCode::Char('c') && key.modifiers.contains(KeyModifiers::CONTROL))
        {
            return Ok(None);
        }
        if key.code == KeyCode::Enter {
            if let Some(session) = form.submit() {
                return Ok(Some(session));
            }
        } else {
            form.edit(key);
        }
    }
}

impl Form {
    /// Advance from the description or validate and start the session.
    fn submit(&mut self) -> Option<(String, u64)> {
        if self.message.trim().is_empty() {
            self.error = "Add a description";
            self.editing_minutes = false;
            return None;
        }
        if !self.editing_minutes {
            self.editing_minutes = true;
            self.error = "";
            return None;
        }
        let minutes = if self.minutes.is_empty() {
            Ok(25)
        } else {
            self.minutes.parse::<u64>()
        };
        if let Ok(minutes) = minutes
            && session_duration(minutes).is_ok()
        {
            return Some((self.message.trim().to_owned(), minutes));
        }
        self.error = "Use a positive whole number of minutes";
        None
    }

    /// Edit the selected field without treating description characters as shortcuts.
    fn edit(&mut self, key: KeyEvent) {
        self.error = "";
        if matches!(key.code, KeyCode::Tab | KeyCode::BackTab) {
            self.editing_minutes = !self.editing_minutes;
            return;
        }
        let value = if self.editing_minutes {
            &mut self.minutes
        } else {
            &mut self.message
        };
        match key.code {
            KeyCode::Backspace => {
                value.pop();
            }
            KeyCode::Char('u') if key.modifiers.contains(KeyModifiers::CONTROL) => value.clear(),
            KeyCode::Char(character)
                if !key
                    .modifiers
                    .intersects(KeyModifiers::CONTROL | KeyModifiers::ALT) =>
            {
                value.push(character);
            }
            _ => {}
        }
    }
}

/// Render two fields with a shared tomato header and concise controls.
fn draw(frame: &mut Frame, form: &Form) {
    let [art, _, description, minutes, error, controls] = Layout::vertical([
        Constraint::Length(7),
        Constraint::Length(1),
        Constraint::Length(3),
        Constraint::Length(3),
        Constraint::Length(1),
        Constraint::Length(1),
    ])
    .areas(ui::panel(frame, 16));
    ui::header(frame, art);
    field(
        frame,
        description,
        "Description",
        &form.message,
        "",
        !form.editing_minutes,
    );
    field(
        frame,
        minutes,
        "Minutes",
        &form.minutes,
        "25",
        form.editing_minutes,
    );
    frame.render_widget(Paragraph::new(form.error).light_red().centered(), error);
    frame.render_widget(
        Paragraph::new("Tab  switch   Enter  next/start   Esc  cancel")
            .dark_gray()
            .centered(),
        controls,
    );
}

/// Keep the active input visible with a simple trailing caret and rounded border.
fn field(frame: &mut Frame, area: Rect, title: &str, value: &str, placeholder: &str, active: bool) {
    let color = if active {
        Color::LightRed
    } else {
        Color::DarkGray
    };
    let displayed = if value.is_empty() { placeholder } else { value };
    let capacity = usize::from(area.width.saturating_sub(4));
    let skip = displayed.chars().count().saturating_sub(capacity);
    let tail: String = displayed.chars().skip(skip).collect();
    let caret = if active { "_" } else { "" };
    let block = Block::bordered()
        .border_type(BorderType::Rounded)
        .title(format!(" {title} "))
        .border_style(Style::default().fg(color));
    frame.render_widget(Paragraph::new(format!("{tail}{caret}")).block(block), area);
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Empty descriptions and invalid minutes cannot start a session.
    #[test]
    fn validates_form() {
        let mut form = Form::default();
        assert!(form.submit().is_none());
        form.message = " Write notes ".to_owned();
        assert!(form.submit().is_none());
        assert_eq!(form.submit(), Some(("Write notes".to_owned(), 25)));
        for invalid in ["0", "abc", "18446744073709551615"] {
            form.minutes = invalid.to_owned();
            assert!(form.submit().is_none());
        }
        form.minutes = "1".to_owned();
        assert_eq!(form.submit(), Some(("Write notes".to_owned(), 1)));
    }

    /// Navigation and Unicode backspacing edit the intended field.
    #[test]
    fn edits_fields() {
        let mut form = Form::default();
        for character in ['q', 'é'] {
            form.edit(KeyEvent::new(KeyCode::Char(character), KeyModifiers::NONE));
        }
        form.edit(KeyEvent::new(KeyCode::Backspace, KeyModifiers::NONE));
        assert_eq!(form.message, "q");
        form.edit(KeyEvent::new(KeyCode::Tab, KeyModifiers::NONE));
        form.edit(KeyEvent::new(KeyCode::Char('5'), KeyModifiers::NONE));
        assert_eq!(form.minutes, "5");
        form.edit(KeyEvent::new(KeyCode::Char('u'), KeyModifiers::CONTROL));
        assert_eq!(form.minutes, "");
    }
}
