//! Shared minimal tomato artwork and timer layout.
use ratatui::{
    Frame,
    layout::{Constraint, Layout, Rect},
    style::{Color, Style, Stylize},
    text::Line,
    widgets::{Gauge, Paragraph},
};
use std::time::Duration;

/// Center a compact panel without a surrounding border.
pub fn panel(frame: &Frame, height: u16) -> Rect {
    let [_, column, _] = Layout::horizontal([
        Constraint::Fill(1),
        Constraint::Max(46),
        Constraint::Fill(1),
    ])
    .areas(frame.area());
    let [_, panel, _] = Layout::vertical([
        Constraint::Fill(1),
        Constraint::Length(height),
        Constraint::Fill(1),
    ])
    .areas(column);
    panel
}

/// Draw the title and a small sleepy red tomato.
pub fn header(frame: &mut Frame, area: Rect) {
    let art = vec![
        Line::from("POMMY").bold(),
        Line::from(""),
        Line::from("        \\|/   zZz   ").green(),
        Line::from("     . - - - .      ").light_red(),
        Line::from("   (  -  ㅅ  -  )   ").light_red(),
        Line::from("    ' - . _ . - '   ").light_red(),
    ];
    frame.render_widget(Paragraph::new(art).centered(), area);
}

/// Show only the tomato, title, remaining time, bar, and cancellation controls.
pub fn countdown(frame: &mut Frame, remaining: Duration, ratio: f64) {
    let [art, _, clock, bar, _, controls] = Layout::vertical([
        Constraint::Length(7),
        Constraint::Length(1),
        Constraint::Length(2),
        Constraint::Length(1),
        Constraint::Length(1),
        Constraint::Length(1),
    ])
    .areas(panel(frame, 13));
    header(frame, art);
    let seconds = remaining
        .as_secs()
        .saturating_add(u64::from(remaining.subsec_nanos() > 0));
    frame.render_widget(
        Paragraph::new(format!("{:02}:{:02}", seconds / 60, seconds % 60))
            .bold()
            .centered(),
        clock,
    );
    frame.render_widget(
        Gauge::default()
            .ratio(ratio)
            .label("")
            .gauge_style(Style::default().fg(Color::LightRed))
            .use_unicode(true),
        bar,
    );
    frame.render_widget(
        Paragraph::new("q / Esc / Ctrl+C  cancel")
            .dark_gray()
            .centered(),
        controls,
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Keep the sleeping text beside the stem despite the wide mouth character.
    #[test]
    fn aligns_tomato() {
        let mut terminal =
            ratatui::Terminal::new(ratatui::backend::TestBackend::new(20, 7)).unwrap();
        terminal.draw(|frame| header(frame, frame.area())).unwrap();
        let buffer = terminal.backend().buffer();
        assert_eq!(buffer[(9, 2)].symbol(), "|");
        assert_eq!(buffer[(14, 2)].symbol(), "z");
        assert_eq!(buffer[(9, 4)].symbol(), "ㅅ");
    }

    /// Render the essential timer content and tolerate small terminal sizes.
    #[test]
    fn renders_countdown() {
        for (width, height) in [(80, 24), (20, 5)] {
            let mut terminal =
                ratatui::Terminal::new(ratatui::backend::TestBackend::new(width, height)).unwrap();
            terminal
                .draw(|frame| countdown(frame, Duration::from_secs(65), 0.5))
                .unwrap();
            if width == 80 {
                let content: String = terminal
                    .backend()
                    .buffer()
                    .content
                    .iter()
                    .map(ratatui::buffer::Cell::symbol)
                    .collect();
                assert!(content.contains("01:05"));
                assert!(content.contains("POMMY"));
                assert!(content.contains("\\|/   zZz"));
                assert!(content.contains('ㅅ'));
                assert!(!content.contains("Time to focus"));
            }
        }
    }
}
