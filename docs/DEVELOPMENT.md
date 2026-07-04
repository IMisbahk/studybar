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
| `StudyBar/StudyBarApp.swift` | App entry, `MenuBarExtra`, `ModelContainer`, env wiring |
| `StudyBar/Core/SessionManager.swift` | Timer state machine (idle / running / paused / completed) |
| `StudyBar/Core/DashboardWindowController.swift` | Full `NSWindow` dashboard (⌥⌘H) |
| `StudyBar/Core/FloatingTimerController.swift` | Draggable HUD + fullscreen expand |
| `StudyBar/Core/TimelineEngine.swift` | Day grouping, segment blocks, filters |
| `StudyBar/Core/AnalyticsEngine.swift` | Heatmap, streaks, chart data |
| `StudyBar/Core/GamificationEngine.swift` | XP, levels, achievement unlocks |
| `StudyBar/Core/InsightsEngine.swift` | Smart insights tab |
| `StudyBar/Core/StudyTheme.swift` | Theme presets + menu bar styles |
| `StudyBar/Core/AmbientSoundEngine.swift` | Procedural ambient audio (offline) |
| `StudyBar/Core/UpdateInstaller.swift` | GitHub release fetch + DMG install |
| `StudyBar/Core/GlobalHotkeyManager.swift` | ⌥⌘ global/local shortcuts |
| `StudyBar/Models/` | SwiftData models (`Subject`, `Topic`, `StudySession`, `SessionSegment`, …) |
| `StudyBar/Views/` | SwiftUI popover + dashboard UI |
| `VERSION` | Canonical semver string |
| `StudyBar.xcodeproj` | Xcode project (deployment target macOS 14.0) |

## Architecture notes

- **`@Observable`** (`SessionManager`) injected via `.environment()` — not `ObservableObject`
- **Menu bar label** (`MenuBarLabelView`) receives `SessionManager` as a plain property because the `MenuBarExtra` label closure doesn't inherit `.environment()`
- **`StudySession`** denormalizes `subjectName` / `topicName` as strings so history survives subject renames/deletes
- **`SessionSegment`** records active/pause/systemPause intervals for timeline rendering
- **Settings navigation** uses `NavigationStack` instead of `.sheet` — sheets are unreliable inside `MenuBarExtra(.window)` popovers
- **Never wrap `PopoverRootView` in an outer `ScrollView`** — kills click targets on macOS
- **New Swift files** must be added to `project.pbxproj` manually (no xcodegen)

## Common commands

```bash
# debug build (faster iteration)
./scripts/build.sh Debug

# release build
./scripts/build.sh Release

# package zip + dmg + checksums into dist/
./scripts/package.sh Release

# bump version everywhere
./scripts/bump-version.sh 2.14.0

# refresh Homebrew cask from dist/ (after package)
./scripts/update-homebrew-cask.sh
```

## Signing

Debug/CI builds use ad-hoc signing (`Sign to Run Locally`). For distribution outside your machine, that's sufficient for open-source GitHub releases.

To use a Development Team, open the project in Xcode → **StudyBar** target → **Signing & Capabilities** → select your team.

## Data location

SwiftData stores data at `~/Library/Application Support/StudyBar/studybar.store`. It persists across rebuilds and updates. Legacy sandbox data (`~/Library/Containers/com.misbah.studybar/...`) is auto-migrated on first launch.

## CI

- **CI** (`.github/workflows/ci.yml`) — builds Release on push/PR to `main`
- **Release** (`.github/workflows/release.yml`) — on `v*` tag push, packages zip/dmg/sha256 and publishes a GitHub Release

## Product spec

See [PRODUCT.md](../PRODUCT.md) for the original feature spec and explicit non-goals (no cloud sync, no Pomodoro chaining, etc.).
