# Development

## Prerequisites

- macOS 14+
- [Xcode](https://developer.apple.com/xcode/) from the App Store
- After installing Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
```

## Clone and build

```bash
git clone https://github.com/IMisbahk/studybar.git
cd studybar
./scripts/build.sh Debug
open build/Build/Products/Debug/StudyBar.app
```

## Project structure

| Path | Purpose |
|------|---------|
| `StudyBar/StudyBarApp.swift` | App entry, `MenuBarExtra`, `ModelContainer` |
| `StudyBar/Core/SessionManager.swift` | Timer state machine (idle / running / paused) |
| `StudyBar/Core/NotificationManager.swift` | UserNotifications wrapper |
| `StudyBar/Models/` | SwiftData models (`Subject`, `Topic`, `StudySession`) |
| `StudyBar/Views/` | SwiftUI popover UI |
| `VERSION` | Canonical semver string |
| `StudyBar.xcodeproj` | Xcode project (deployment target macOS 14.0) |

## Architecture notes

- **`@Observable`** (`SessionManager`) injected via `.environment()` — not `ObservableObject`
- **Menu bar label** (`MenuBarLabelView`) receives `SessionManager` as a plain property because the `MenuBarExtra` label closure doesn’t inherit `.environment()`
- **`StudySession`** denormalizes `subjectName` / `topicName` as strings so history survives subject renames/deletes
- **Settings navigation** uses `NavigationStack` instead of `.sheet` — sheets are unreliable inside `MenuBarExtra(.window)` popovers

## Common commands

```bash
# debug build (faster iteration)
./scripts/build.sh Debug

# release build
./scripts/build.sh Release

# package zip + dmg + checksums into dist/
./scripts/package.sh Release

# bump version everywhere
./scripts/bump-version.sh 1.1.0
```

## Signing

Debug/CI builds use ad-hoc signing (`Sign to Run Locally`). For distribution outside your machine, that’s sufficient for open-source GitHub releases.

To use a Development Team, open the project in Xcode → **StudyBar** target → **Signing & Capabilities** → select your team.

## Data location

SwiftData stores data at `~/Library/Application Support/StudyBar/studybar.store`. It persists across rebuilds and updates. Legacy sandbox data (`~/Library/Containers/com.misbah.studybar/...`) is auto-migrated on first launch.

## CI

- **CI** (`.github/workflows/ci.yml`) — builds Release on push/PR to `main` or `master`
- **Release** (`.github/workflows/release.yml`) — on `v*` tag push, packages zip/dmg/sha256 and publishes a GitHub Release

## Product spec

See [PRODUCT.md](../PRODUCT.md) for the full feature spec and explicit non-goals (no cloud sync, no Pomodoro chaining, etc.).
