# Changelog

All notable changes to StudyBar are documented here. Versioning follows [Semantic Versioning](https://semver.org/).

## [1.5.0] - 2026-07-02

### Added
- **Analytics dashboard**: GitHub-style study heatmap, weekly bar chart, subject breakdown
- **Notes browser**: dedicated searchable view for all session notes
- **Export**: save heatmap as PNG, export session history as CSV
- Streak tracking (current + longest)

## [1.4.0] - 2026-07-02

### Added
- **Dashboard window**: full StudyBar app window with sidebar (Overview, History, Settings)
- Gear icon in menu bar popover opens the dashboard
- **⌘Q behavior**: closes dashboard window only; menu bar agent keeps running

### Changed
- Settings available in both compact popover and full dashboard layouts

## [1.3.0] - 2026-07-02

### Added
- **Stopwatch mode** (∞ duration): open-ended study sessions that count up until you stop
- **In-app updater**: downloads release DMG with progress, verifies SHA256, opens installer locally
- Larger tab bar hit targets in the menu bar popover (full button area is clickable)

### Changed
- Menu bar and floating timer show elapsed time for stopwatch sessions
- History distinguishes stopwatch sessions with a stopwatch icon

## [1.2.1] - 2026-07-02

### Fixed
- Menu bar popover no longer closes immediately or ignores clicks
- Floating timer no longer shows when idle (was blocking menu bar interaction)
- Floating timer hides while popover is open; deferred service startup until after launch
- Tab navigation restored with stable local state; History/Settings reachable again

## [1.2.0] - 2026-07-01

### Added
- Phase 1 polish: spring-animated progress ring with urgent pulse (<5 min) and paused breathing
- Menu bar icon morph + completion bounce/checkmark animation
- Global keyboard shortcuts: ⌥⌘S (start last), ⌥⌘P (pause), ⌥⌘R (resume), ⌥⌘E (+10 min), ⌥⌘H (open history)
- Floating mini timer panel (always on top, draggable, opacity + auto-hide settings)
- Session notes field (optional, saved with session, searchable in History)
- Auto-pause on Mac sleep and screen lock; auto-resume on wake/unlock (only if auto-paused)
- Rich notifications with Pause, +10 min, and Stop actions
- Redesigned Settings with grouped sections and shortcuts reference

### Changed
- Improved notification copy (title/subtitle/body)
- History view includes search across subjects, topics, and notes

## [1.1.2] - 2026-07-01

### Added
- Settings → Updates: checks GitHub for new releases, download button or "up to date"

### Fixed
- DMG window matches background aspect ratio (no white bar on the side)
- DMG icons aligned on the same row; `.background` and `.fseventsd` hidden
- DMG installer: white background, black arrow and instruction text; icon labels readable

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

[1.5.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.5.0
[1.4.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.4.0
[1.3.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.3.0
[1.2.1]: https://github.com/IMisbahk/studybar/releases/tag/v1.2.1
[1.2.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.2.0
[1.1.2]: https://github.com/IMisbahk/studybar/releases/tag/v1.1.2
[1.1.1]: https://github.com/IMisbahk/studybar/releases/tag/v1.1.1
[1.1.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.1.0
[1.0.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.0.0
