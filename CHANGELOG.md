# Changelog

All notable changes to StudyBar are documented here. Versioning follows [Semantic Versioning](https://semver.org/).

## [2.0.0] - 2026-07-03

**Production-ready release.** See [RELEASE_NOTES_v2.0.0.md](RELEASE_NOTES_v2.0.0.md) for the public announcement.

### Added
- Suggested session duration on start screen (from Insights history)
- Pin up to 3 favorite subjects (star in Manage Subjects)
- Daily & weekly study goals with progress rings (timer + dashboard)
- Pause-too-long notification (10 min default)
- Sunday weekly recap notification
- First-launch onboarding flow
- Backup & restore (local zip of SwiftData store)
- Automatic updates: check every 6 hours, install when idle

### Changed
- StudyBar 2.0 version bump — core product feature-complete

## [1.8.1] - 2026-07-03

### Fixed
- Study heatmap rendering on Analytics (removed rasterization that broke the grid)

### Added
- **Session log** — delete individual sessions or bulk-delete under 5 min (Timeline → Session log)
- **Study reminders** — daily peak-focus-time notification + inactivity nudges (Settings)
- XP/achievements recalculate after session deletion

## [1.8.0] - 2026-07-03

### Added
- **Smart Insights** dashboard tab — local pattern detection, no cloud
- Peak focus window, strongest weekday, subject duration comparisons
- Consistency trend (two-week comparison)
- Typical session length + suggested preset (25/45/50/90 min)
- Burnout warnings: long days, late-night study, heavy 3-day stretches
- Break suggestions from pause patterns
- Weekly and monthly narrative summaries

## [1.7.58] - 2026-07-03

### Fixed
- Analytics scroll performance — cached snapshot, lazy layout, rasterized chart cards

### Changed
- Export buttons and save toast pinned to top of Analytics page
- Support and GitHub links moved below Updates in Settings

## [1.7.57] - 2026-07-03

### Added
- **Monthly report PDF** — current month summary with achievements earned
- Export from Analytics → Downloads

## [1.7.56] - 2026-07-03

### Added
- **JSON** and **Markdown** session exports

## [1.7.55] - 2026-07-03

### Added
- **Consistency score** and **Focus score** on Analytics dashboard

## [1.7.54] - 2026-07-03

### Added
- Rolling 7-day / 30-day averages
- Week-over-week and month-over-month comparison stats
- **Time-of-day** chart with hover

## [1.7.53] - 2026-07-03

### Added
- **Daily** (30-day) and **monthly** study charts
- Interactive chart hover cards on daily / weekly / monthly charts

## [1.7.52] - 2026-07-03

### Added
- Analytics overview stats: total hours, avg/longest/shortest session, peak weekday/hour, YTD
- Subject pie chart

## [1.7.5] - 2026-07-03

### Added
- **Support StudyBar** link in Settings (above GitHub)
- Galaxy nebula/constellation tiers and visual polish

## [1.7.4] - 2026-07-03

### Added
- **Galaxy** dashboard — each subject is a planet that grows with study hours
- Planet tiers: rings, moons, stars (cosmetic only)

## [1.7.3] - 2026-07-03

### Added
- **~100 achievements** with category filters
- Unlock banner animations in dashboard (respects Reduced Motion)

## [1.7.2] - 2026-07-03

### Added
- Achievement engine: sessions, hours, streaks, habits, weekdays, per-subject mastery
- **Achievements** dashboard tab

## [1.7.1] - 2026-07-03

### Added
- **Profile** dashboard: overall level, XP bar, streaks, per-subject level cards

## [1.7.0] - 2026-07-03

### Added
- XP system — 1 XP per minute studied, per-subject and overall levels
- `ProfileProgress`, `SubjectProgress`, `AchievementUnlock` SwiftData models
- Automatic backfill from existing session history on first launch

## [1.6.51] - 2026-07-03

### Fixed
- **Restart to Update** from dashboard Settings now quits the app (was blocked by ⌘Q dashboard-close handler)

## [1.6.5] - 2026-07-03

### Added
- Timeline **filters**: subject chips, date range (7/30/90 days), completed-only toggle, search
- Popover History tab renamed to **Timeline** with compact 14-day preview + **Open full** link
- ⌥⌘H opens dashboard directly on Timeline

### Changed
- Dashboard **History** sidebar replaced by **Timeline**

## [1.6.4] - 2026-07-03

### Added
- Timeline **zoom** modes: **Day** (24h), **Focus** (6am–11pm), **Compact** (dense rows)

## [1.6.3] - 2026-07-03

### Added
- Git-style vertical scroll through study days (rail + dots, newest first)
- Dashboard **Timeline** section

## [1.6.2] - 2026-07-03

### Added
- Colored session blocks per subject
- Hover card: start/end, duration, subject, notes, pauses, resume points, breaks between sessions

## [1.6.1] - 2026-07-03

### Added
- `TimelineEngine` — groups sessions by day, positions blocks on a horizontal time axis
- `TimelineDayRowView` — one row per day with hour grid

## [1.6.0] - 2026-07-03

### Added
- `SessionSegment` SwiftData model — logs active, user-pause, and auto-pause intervals per session
- `SessionManager` records pause/resume segments during live sessions

## [1.5.33] - 2026-07-03

### Added
- Exports (heatmap PNG, sessions CSV) save directly to **Downloads**
- macOS notification on export with **Show in Finder** action
- In-app green confirmation banner with **Show in Finder** button

### Removed
- Star rating feedback UI from Settings

## [1.5.32] - 2026-07-03

### Added
- 5-star feedback row in Settings (below GitHub link); shows GitHub star count

### Fixed
- **Restart to Update** actually works: `hdiutil -quiet` returned no mount path (broken since v1.5.3)
- Relauncher now runs detached with `nohup` so it survives app quit
- Update errors show log path at `~/Library/Application Support/StudyBar/Updates/install.log`

## [1.5.31] - 2026-07-03

### Fixed
- **Data loss after update**: v1.5.3 sandbox removal moved SwiftData to a new empty path
- App now uses a fixed store at `~/Library/Application Support/StudyBar/studybar.store`
- Automatically migrates sessions from the old sandbox container on first launch

## [1.5.3] - 2026-07-03

### Added
- Heatmap hover card: date, total time, per-subject breakdown when hovering green cells
- **Restart to Update**: one-click install — quits, replaces the app, and relaunches automatically

### Fixed
- Heatmap range picker layout (no more vertical "Range" label)
- Removed app sandbox so in-place updates can write to `/Applications`

### Changed
- Update flow no longer opens a DMG for manual drag-and-drop

## [1.5.2] - 2026-07-02

### Added
- Heatmap range modes: **Weekly**, **Monthly**, **YTD**, **Annual** (segmented picker)
- Weekday labels, auto-scroll to most recent days, larger cells in weekly view

### Fixed
- Heatmap not showing today's study (date lookup + invisible green on dark backgrounds)
- Heat levels use minute buckets so any study day is clearly visible

## [1.5.1] - 2026-07-02

### Fixed
- App crash on launch when upgrading from pre-1.3.0 data (SwiftData `openEnded` migration)
- Corrupt migration now backs up the old store and recreates cleanly instead of `fatalError`
- Clearer install docs: menu-bar-only app + Gatekeeper bypass steps

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




[1.6.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.6.0
[1.5.33]: https://github.com/IMisbahk/studybar/releases/tag/v1.5.33
[1.5.32]: https://github.com/IMisbahk/studybar/releases/tag/v1.5.32
[1.5.31]: https://github.com/IMisbahk/studybar/releases/tag/v1.5.31
[1.5.3]: https://github.com/IMisbahk/studybar/releases/tag/v1.5.3
[1.5.2]: https://github.com/IMisbahk/studybar/releases/tag/v1.5.2
[1.5.1]: https://github.com/IMisbahk/studybar/releases/tag/v1.5.1
[1.5.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.5.0
[1.4.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.4.0
[1.3.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.3.0
[1.2.1]: https://github.com/IMisbahk/studybar/releases/tag/v1.2.1
[1.2.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.2.0
[1.1.2]: https://github.com/IMisbahk/studybar/releases/tag/v1.1.2
[1.1.1]: https://github.com/IMisbahk/studybar/releases/tag/v1.1.1
[1.1.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.1.0
[1.0.0]: https://github.com/IMisbahk/studybar/releases/tag/v1.0.0
