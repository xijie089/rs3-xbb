# Changelog

## 0.2.0 (unreleased)

- Settings now use PrettyUI, which is a required dependency.
- Open settings from Plugins or Plugin Hub instead of the bar header.
- Added category colors and opacity, plus individual buff/debuff overrides.
- Timers remember observed durations across reloads and count through rounded minute/hour labels.
- Added support for combined timer and stack-count labels, such as `20 (12)` for 20 seconds and 12 stacks.

## 0.1.1

- Added title-bar dragging for the settings window.
- Settings window position is saved across reopening, plugin reloads, and game restarts.

## 0.1.0

- Initial version with named buff/debuff bars, countdowns, stack counts, and hover descriptions.
- Combined or separate stacks, hidden effects, pinned slots, and reservations for absent effects.
- Optional replacement of the native bars and missing-buff warnings from presets or observed buffs.
- Saved bar positions, settings, and observed effects between sessions.
