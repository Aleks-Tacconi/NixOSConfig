# Shell design review

The shell combines structured layout improvements (Flickable workspaces, balanced
sideWidth constraints, date-driven calendar agenda, bottom launcher mode tabs) with
the signature glassmorphic look from the remote design: rounded corners, translucent
glass surfaces with layered highlights and shadows, and JetBrainsMono typography.

## Component audit

| Area | Finding | Decision |
| --- | --- | --- |
| Shared surfaces | Adjacent bright/dark borders and a highlight gradient created a bevel; rounded panels conflicted with the rectangular bar. | Replace GlassSurface with flat PanelSurface: one 1px border, 2px corners, no decorative gradient. |
| Top bar | Full-width layout is useful; changing icon sizes made the clusters uneven. | Retain the 36px layout, align control icons to 16px, use one bottom separator. |
| Workspaces | Hover and active looked identical. | Keep the soft fill and add an underline for the active workspace. |
| App menu and tray | Shared popup layout already works; label weight and icon sizing competed. | Inherit flat surfaces and regular text; standardise tray icon size. |
| Launcher | Boxed tabs plus a bordered selected row added redundant frames; focused search had a dark edge. | Place underlined mode tabs below results; keep search first and use a teal selected-row marker. |
| Calendar | Circular selected dates conflicted with the new geometry; white selection was unusually strong. | Lead with a large current date and weekday; keep square date selections, today/focus borders and event dots. |
| Agenda and notifications | List hierarchy is already clear; medium weight appeared on many rows and actions. | Keep list structure and actions, inherit regular text and square control corners. |
| Audio and media | Nested artwork card border repeated the outer panel edge. | Enlarge artwork and allow two-line track titles; use teal for progress and primary playback control. |
| Battery and power profiles | Rounded meter and profile buttons differed from adjacent controls. | Lead with a large percentage beside remaining time; put the meter below and remove duplicate status rows. |
| Network | Traffic badges nested dark boxes within a card; confirmation hover could be white-on-white because Theme.red is white. | Use a tinted icon tile beside the current connection; keep traffic backgrounds flat and confirmation hover readable. |
| Wi-Fi credentials | Form layout and explicit labels are useful. | Retain fields, validation and password behavior; inherit square corners and regular text. |
| Power menu | Clear action list already uses shared rows. | Inherit the flat surface, small corners and consistent power icon. |
| Dock previews | Screenshot caption gradients aid readability, unlike decorative surface gradients. | Retain caption scrims and application icons; square card corners through shared tokens. |
| Workspace overview | Already uses shared popup and card tokens. | Inherit flat framing and regular labels; retain previews and spatial arrangement. |
| Shared labels | Group labels multiplied a muted colour by another opacity, weakening legibility. | Remove the extra opacity; reserve medium weight for panel titles. |
| Spinners, dividers and scroll indicators | Functional geometry carries state and position. | Retain it; circular activity indicators are not surface decoration. |
| Data/services | No visual styling responsibility. | Leave notification, network, battery, launcher-search and menu backends unchanged. |

## Verification scope

Render the real shared surface, headers, launcher controls, calendar grid, status
cells, action rows and media buttons in an offscreen Quickshell window. Review
text, icon alignment, selection states and edges on dark and light backgrounds.
Parse all QML and run the existing UI logic tests. Compositor blur, live services,
and interactions across the full desktop still require a live session review.
