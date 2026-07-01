# StudyBar

A native macOS menu bar study timer. Pick a subject, start a session, and the menu bar icon becomes a live countdown with a progress ring. Fully local — no accounts, no cloud, no network.

![Active session screenshot](docs/screenshots/active-session.png)

## Features

- **Menu bar native** — lives in the menu bar only (no dock icon, no main window)
- **Live countdown** — icon morphs to `mm:ss` + animated progress ring while studying
- **Subjects & topics** — editable lists, persisted with SwiftData
- **Duration presets** — 25 / 50 / 90 min, or custom
- **Session controls** — pause, resume, stop early, extend +5 / +10 min
- **Notifications** — alerts when a session starts and completes
- **History** — today / week / month / daily-average totals, per-subject breakdown
- **Settings** — launch at login, sound on session end, manage subjects, quit

**Requirements:** macOS 14.0 (Sonoma) or later · Apple Silicon or Intel

## Install

### Option 1 — Download release (recommended)

1. Open [Releases](https://github.com/IMisbahk/studybar/releases/latest)
2. Download `StudyBar-x.y.z.zip` or `.dmg`
3. Drag **StudyBar.app** to **Applications**
4. Open StudyBar (right-click → Open the first time if Gatekeeper blocks unsigned builds)

Verify checksum (optional):

```bash
shasum -a 256 -c StudyBar-1.0.0.sha256
```

### Option 2 — Install script (latest release)

```bash
curl -fsSL https://raw.githubusercontent.com/IMisbahk/studybar/main/scripts/install-release.sh | bash
```

Or pin a version:

```bash
curl -fsSL https://raw.githubusercontent.com/IMisbahk/studybar/main/scripts/install-release.sh | bash -s -- 1.0.0
```

### Option 3 — Homebrew (local cask)

```bash
brew install --cask ./packaging/homebrew/StudyBar.rb
```

> After each new release, update `version` and `sha256` in `packaging/homebrew/StudyBar.rb` (see [docs/RELEASING.md](docs/RELEASING.md)).

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
3. Allow notifications when macOS asks
4. Click the icon again during a session for pause / stop / extend
5. Check **History** and **Settings** via the bottom tab bar

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

| Artifact | Description |
|----------|-------------|
| `StudyBar-x.y.z.zip` | App bundle, ready to drag to Applications |
| `StudyBar-x.y.z.dmg` | Disk image for familiar macOS install flow |
| `StudyBar-x.y.z.sha256` | SHA-256 checksums for zip + dmg |

Releases are built automatically when a `v*` tag is pushed. Maintainer guide: [docs/RELEASING.md](docs/RELEASING.md).

## Project layout

```
StudyBar/           Swift source (Models, Core, Views)
StudyBar.xcodeproj/ Xcode project
scripts/            build, package, install, version bump
packaging/          Homebrew cask
docs/               install, development, releasing guides
.github/workflows/  CI + release automation
```

## Privacy

All data stays on your Mac. SwiftData stores subjects, topics, and session history locally. No analytics, no network calls.

## License

[MIT](LICENSE) © Misbah Khursheed

## Contributing

Issues and PRs welcome. See [PRODUCT.md](PRODUCT.md) for the product spec and non-goals.
