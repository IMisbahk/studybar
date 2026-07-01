# Changelog

All notable changes to StudyBar are documented here. Versioning follows [Semantic Versioning](https://semver.org/).

## [1.1.2] - 2026-07-01

### Added
- Settings → Updates: checks GitHub for new releases, download button or "up to date"

### Fixed
- DMG window matches background aspect ratio (no white bar on the side)
- DMG icons aligned on the same row; `.background` and `.fseventsd` hidden

## [1.1.1] - 2026-07-01

### Changed
- Simplified app icon: black open book on white, square
- Menu bar back to native book symbol (no oversized app icon)
- Popover logo uses clean asset without extra border or shadow

## [1.1.0] - 2026-07-01

### Added
- Custom app icon (book + timer ring)
- Styled DMG installer with background image and Applications folder shortcut
- Today's study time pill on the timer screen
- Recent subjects quick-pick chips
- Labeled tab bar (Timer / History / Settings)
- Settings About section with version + GitHub link
- Elapsed vs planned time on active session view
- History stats as card grid
- ⌘↩ keyboard shortcut to start a session
- Empty state when no subjects exist yet

### Changed
- Menu bar uses app icon when idle (custom logo instead of generic SF Symbol)
- Active session buttons use icons + labels
- Polished idle header with logo and tagline

## [1.0.0] - 2026-07-01

First public release.

### Added
- Menu bar app with idle book icon and live countdown + progress ring during sessions
- Subject/topic picker with inline add; duration presets (25/50/90 min) and custom input
- Active session controls: pause/resume, stop early, extend +5/+10 min
- Start and completion notifications via UserNotifications
- Session history with today/week/month/daily-average totals and per-subject breakdown
- Settings: launch at login, sound on session end, manage subjects/topics, quit
- SwiftData persistence for subjects, topics, and session history
- Local-only — no accounts, cloud sync, or network calls

[1.1.2]: https://github.com/IMisbahk/studybar/releases/tag/v1.1.2
[1.1.1]: https://github.com/IMisbahk/studybar/releases/tag/v1.1.1
[1.1.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.1.0
[1.0.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.0.0
