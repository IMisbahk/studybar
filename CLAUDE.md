# StudyBar — session notes

## Environment (updated 2026-07-03)
- **Xcode 26.6** — `xcodebuild -scheme StudyBar build` verified through v1.6.5.
- The `.xcodeproj` was hand-written (no `xcodegen`). New Swift files must be added to
  `project.pbxproj` PBXFileReference + PBXBuildFile + group + Sources phase manually.

## Key deviations from product.md, called out to Misbah already
- **Deployment target is macOS 14.0, not 13.0.** SwiftData requires macOS 14+;
  MenuBarExtra only needs 13+. Since SwiftData was the explicit ask, bumped the
  target rather than falling back to JSON. Given it's mid-2026 this costs nothing
  in practice.
- `StudySession` stores `subjectName`/`topicName` as denormalized string snapshots,
  not relationships to `Subject`/`Topic` - so history stays intact if a subject is
  later renamed or deleted. `Subject`/`Topic` do have a real cascade-delete
  relationship between each other though.
- "Daily average" (history stat, from the product.md line added mid-session) is
  total studied time / days-since-first-session. Not spec'd precisely, easy to
  change if a different window (e.g. trailing 7 days) is wanted instead.
- Skipped the right-click/secondary-menu nice-to-have - not trivial with
  `.menuBarExtraStyle(.window)` (would need to drop to raw NSStatusItem/AppKit).
  Spec said skip if non-trivial.
- **⌥⌘H** opens dashboard **Timeline** directly (popover tab also switches to compact timeline).

## Architecture
- `Core/SessionManager.swift` - state machine; logs `StudySession` + **`SessionSegment`** pause intervals.
- `Core/TimelineEngine.swift` - day grouping, block positioning, filters, subject colors.
- `Models/SessionSegment.swift` - `active` / `pause` / `systemPause` per session.
- `Core/DashboardWindowController.swift` + `Core/AppDelegate.swift` - full `NSWindow` dashboard;
  **⌘Q closes dashboard only** when open (`applicationShouldTerminate` → `.terminateCancel`).
- `Core/UpdateInstaller.swift` - fetches GitHub release DMG + sha256, downloads with progress,
  verifies checksum, `openInstaller()` mounts DMG via `NSWorkspace` (sandbox can't self-replace).
- `Core/AnalyticsEngine.swift` + `Core/ExportService.swift` - heatmap levels, streaks, PNG/CSV export.
- `Core/GlobalHotkeyManager.swift` - NSEvent global+local monitors for ⌥⌘ shortcuts.
- `Core/FloatingTimerController.swift` - `NSPanel`; only during active sessions, hidden when idle
  and while menu popover is open.
- `Views/Dashboard/` - sidebar: Overview, Analytics, Notes, **Timeline**, Settings.
  `TimelineView` + `TimelineDayRowView` + `TimelineSessionTooltip`.
- `Views/PopoverRootView.swift` - compact timer popover; tab bar uses `contentShape(Rectangle())`
  for full-width hit targets. **Never wrap in outer ScrollView** — kills clicks on macOS.

## Phase 1 manual smoke-test checklist (v1.2.0)
- [ ] Start session → ring animates smoothly, menu bar shows countdown
- [ ] Under 5 min remaining → ring pulses red
- [ ] Pause → breathing animation on ring (menu bar + popover + floating timer)
- [ ] Complete session → bounce + checkmark in menu bar, Glass sound if enabled
- [ ] Add notes during session → appears in History, searchable
- [ ] ⌥⌘S starts last session when idle
- [ ] ⌥⌘P/R/E work during active session (global, even when popover closed)
- [ ] ⌥⌘H → click menu bar → History tab opens
- [ ] Floating timer: draggable, opacity slider works, auto-hides when idle
- [ ] Lock screen while running → auto-pauses; unlock → auto-resumes
- [ ] Close lid / sleep → auto-pause; wake → auto-resume
- [ ] Notification actions: Pause, +10 min, Stop work from banner
- [ ] Reduced Motion in Accessibility → animations respect setting

## Phase 3 Timeline (v1.6.0–1.6.5) — shipped 2026-07-03
- Segments, engine, tooltips, dashboard timeline, zoom, filters/popover compact view
- Pre-1.6.0 sessions lack segments — shown as single blocks (fine)

## Phase 4 Gamification (v1.7.0–1.7.5) — shipped 2026-07-03
- XP/levels, ~83 global + 8 per-subject achievement templates, galaxy planets
- `GamificationEngine` runs on session log + backfill on launch
- Support link: https://rzp.io/rzp/studybar in Settings

## Roadmap backlog (post v1.7.5)
Phases 5-9: Apple integration, White noise, Smart insights, Command palette, Customization.

## Releases shipped 2026-07-03
- **v1.6.0–1.6.5** — Phase 3 Timeline

## Releases shipped 2026-07-02
- **v1.3.0** — stopwatch mode, in-app updater, tab hit targets
- **v1.4.0** — dashboard window, ⌘Q closes window only
- **v1.5.0** — analytics heatmap, notes browser, PNG/CSV export

## DMG packaging notes (2026-07-01)
- `packaging/dmg/background.png` is **600×400**, white bg, black arrow + instruction text.
  Window bounds in `configure.applescript` are derived from PNG dimensions.
- Hide `.background` folder three ways: `/.hidden` file, `chflags hidden`, and
  `com.apple.FinderInfo` xattr with kIsInvisible. **Do not** use `SetFile -a V` on
  the mounted volume — causes write permission errors (-61).
- Post-mount copy of `.background` failed on read-only attach; stage everything in
  `srcfolder` instead (including `.background` + `.hidden`).
- Icon Y at ~28% of bg height leaves room for labels below icons on white bg.
