# StudyBar

<p align="center">
  <img src="docs/app-icon.png" width="128" alt="StudyBar app icon">
</p>

A native macOS menu bar study timer. Pick a subject, start a session, and the menu bar icon becomes a live countdown with a progress ring. Dashboard analytics, XP, ambient sounds, themes — fully local, no accounts, no cloud.

**Latest release:** [v2.13.0](https://github.com/IMisbahk/studybar/releases/tag/v2.13.0) · **Current source:** [`2.13.5`](VERSION)

![Active session screenshot](docs/screenshots/active-session.png)

## Features

### Core timer
- **Menu bar native** — lives in the menu bar (no Dock icon); optional floating HUD and full dashboard window
- **Live countdown** — icon morphs to `mm:ss` + animated progress ring while studying
- **Subjects & topics** — editable lists, persisted with SwiftData
- **Duration presets** — 25 / 50 / 90 min, custom input, stopwatch mode, suggested duration from history
- **Session controls** — pause, resume, stop early, extend +5 / +10 min
- **Floating timer** — draggable on-screen HUD; expand to fullscreen focus mode (↗)
- **Ambient sounds** — offline procedural presets (white, pink, rain, storm, ocean, café, fan)

### History & insights
- **History** — today / week / month / daily-average totals, per-subject breakdown, session log with bulk delete
- **Timeline** — day view with pause segments, zoom, filters (dashboard + compact popover tab)
- **Analytics** — heatmap, streaks, charts, time-of-day breakdown, monthly PDF report
- **Smart insights** — study patterns and recommendations
- **Notes browser** — searchable session notes

### Goals & gamification
- **Daily & weekly goals** — progress rings in timer and dashboard
- **XP & levels** — profile progression with achievement unlocks
- **Galaxy view** — per-subject planets tied to study time

### Customization
- **7 color themes** — Classic, Forest, Sunset, Lavender, Ocean, Rose, Monochrome
- **Menu bar styles** — Standard, Compact, Minimal
- **Rounded timer digits** and themed floating timer border

### System integration
- **Notifications** — session start/complete, pause nudge, Sunday recap, study reminders
- **Global shortcuts** — ⌥⌘S start, ⌥⌘P pause, ⌥⌘R resume, ⌥⌘E +10 min, ⌥⌘H timeline (opt-in)
- **Auto-pause** — lock screen, sleep, lid close
- **In-app updates** — check every 6 hours; Settings → Download Update → Restart to Update
- **Backup & restore** — local zip of SwiftData store

**Requirements:** macOS 14.0 (Sonoma) or later · Apple Silicon or Intel

## Install

> **Important:** use the **[Releases](https://github.com/IMisbahk/studybar/releases)** page.
> Do **not** use GitHub's green **Code → Download ZIP** button — that downloads the **source code**, not the app.

### Option 1 — Direct download (recommended)

**[Download latest release](https://github.com/IMisbahk/studybar/releases/latest)**

1. Download `StudyBar-x.y.z.zip` from [Releases](https://github.com/IMisbahk/studybar/releases/latest)
2. Double-click the zip — inside you'll find **`StudyBar-x.y.z.dmg`**
3. Double-click the `.dmg` → drag **StudyBar.app** to **Applications**
4. Launch StudyBar — click the **book icon in the menu bar** (top right). No Dock icon by default.

### First launch — macOS may block the app (one time)

StudyBar isn't notarized (that costs $99/year). macOS may warn that the app "can't be checked for malicious software." **Normal for indie Mac apps.**

**Do this once:**

1. In Finder, go to **Applications**
2. **Right-click** `StudyBar.app` → **Open**
3. Click **Open** in the dialog

After that, double-click works. Or use **Privacy & Security → Open Anyway**, or:

```bash
xattr -cr /Applications/StudyBar.app
```

**Or use the install script** — downloads the latest release and strips quarantine:

```bash
curl -fsSL https://raw.githubusercontent.com/IMisbahk/studybar/main/scripts/install-release.sh | bash
```

**In-app updates (v1.5.3+):** Settings → Download Update → **Restart to Update**. Install to `/Applications` for this to work.

Verify checksum (optional — replace version with your download):

```bash
shasum -a 256 -c StudyBar-2.13.0.sha256
```

### Option 2 — Install script

```bash
curl -fsSL https://raw.githubusercontent.com/IMisbahk/studybar/main/scripts/install-release.sh | bash
```

Pin a version:

```bash
curl -fsSL https://raw.githubusercontent.com/IMisbahk/studybar/main/scripts/install-release.sh | bash -s -- 2.13.0
```

### Option 3 — Homebrew (local cask)

```bash
brew install --cask ./packaging/homebrew/StudyBar.rb
```

> Cask pins `version` and `sha256` to a GitHub release. See [docs/RELEASING.md](docs/RELEASING.md) after each release.

### Option 4 — Build from source

```bash
git clone https://github.com/IMisbahk/studybar.git
cd studybar
./scripts/install-from-source.sh
```

Or build without installing:

```bash
./scripts/build.sh Release
open build/Build/Products/Release/StudyBar.app
```

Full details: [docs/INSTALL.md](docs/INSTALL.md)

## Quick start

1. Click the **book icon** in the menu bar
2. Add a subject (+ button), pick a duration, tap **Start Session**
3. Allow notifications when prompted (or skip — reminders stay off)
4. During a session: pause / stop / extend from the popover, floating HUD, or ⌥⌘ shortcuts
5. Open **History**, **Timeline**, or **Settings** via the bottom tab bar
6. Press **⌥⌘H** or use Settings → **Open Dashboard** for the full analytics window

## Development

```bash
git clone https://github.com/IMisbahk/studybar.git
cd studybar
xcodebuild -runFirstLaunch   # once, after installing Xcode
./scripts/build.sh Debug
open build/Build/Products/Debug/StudyBar.app
```

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Versioning & releases

StudyBar uses [Semantic Versioning](https://semver.org/). The canonical version lives in [`VERSION`](VERSION). [CHANGELOG.md](CHANGELOG.md) tracks all releases.

| Artifact | What's inside |
|----------|---------------|
| `StudyBar-x.y.z.zip` | **Only** `StudyBar-x.y.z.dmg` — unzip → open dmg → drag app to Applications |
| `StudyBar-x.y.z.dmg` | Same dmg, for direct download without the zip wrapper |
| `StudyBar-x.y.z.sha256` | SHA-256 checksums for zip + dmg |

Releases build automatically when a `v*` tag is pushed. Maintainer guide: [docs/RELEASING.md](docs/RELEASING.md).

## Project layout

```
StudyBar/           Swift source (Models, Core, Views)
StudyBar.xcodeproj/ Xcode project
scripts/            build, package, install, version bump
packaging/          Homebrew cask + DMG assets
docs/               install, development, releasing guides
release/            public release note drafts
.github/workflows/  CI + release automation
```

## Privacy

All data stays on your Mac. SwiftData stores subjects, topics, and session history at `~/Library/Application Support/StudyBar/`. No analytics, no network calls except optional GitHub update checks.

## License

[MIT](LICENSE) © Misbah Khursheed

## Contributing

Issues and PRs welcome. See [PRODUCT.md](PRODUCT.md) for the product spec and non-goals.
