# StudyBar — session notes

## Environment (updated 2026-07-01)
- **Xcode 26.6 is available on Misbah's Mac** — `xcodebuild -scheme StudyBar build` verified for v1.2.0.
  The old "no Xcode / broken swiftc" note below only applied to an earlier sandbox session.
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
- **⌥⌘H (Open History)** cannot force-open the MenuBarExtra popover — `MenuBarExtra`
  has no public API for that. Hotkey activates the app and queues History tab for
  the next time the user clicks the menu bar icon. Fully global hotkeys for session
  control (start/pause/resume/extend) work without opening the popover.

## Architecture
- `Core/SessionManager.swift` - state machine (idle/running/paused), 1s `Timer`,
  logs `StudySession` on completion/stop, owns `draftNotes`, `lastCompletion` event,
  `startLastSession()`, auto-pause/resume via `pauseBySystem()` / `resumeIfAutoPaused()`.
- `Core/GlobalHotkeyManager.swift` - NSEvent global+local monitors for ⌥⌘ shortcuts.
  Global monitor requires Accessibility permission in System Settings.
- `Core/FloatingTimerController.swift` - `NSPanel` (.normal level, nonactivating); only
  visible during active sessions, hidden when idle and while menu popover is open.
- `Core/PowerEventsMonitor.swift` - `NSWorkspace` sleep/wake + distributed screen
  lock/unlock notifications.
- `Core/NotificationManager.swift` - UNUserNotificationCenterDelegate, categories
  with Pause/+10/Stop actions routed back to SessionManager.
- `Views/PopoverRootView.swift` - Timer/History/Settings tabs; `selectedTab` lives on
  `SessionManager` (survives timer ticks). Content scrolls in a fixed 400pt viewport;
  tab bar is always pinned below (Phase 1 bug: tall content pushed tabs off-screen).
- Settings' "Manage Subjects" uses `NavigationStack`/`NavigationLink`, deliberately
  NOT `.sheet` - sheets are unreliable inside `MenuBarExtra(.window)` popovers.
- `@Observable` throughout; `SessionManager` via `.environment()` for popover,
  plain property for `MenuBarLabelView` (separate view hierarchy).

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

## Roadmap backlog (not in v1.2.0)
Phases 2-9 from product spec: Analytics, Timeline, Gamification/Galaxy, Apple
integration (no Widgets/CLI until separate Xcode targets), White noise, Smart
insights, Command palette/deep links, Customization themes.

## Permissions used this session
- Version bump to 1.2.0, commit, tag, push to origin (per user instruction).

## DMG packaging notes (2026-07-01)
- `packaging/dmg/background.png` is **600×400**, white bg, black arrow + instruction text.
  Window bounds in `configure.applescript` are derived from PNG dimensions.
- Hide `.background` folder three ways: `/.hidden` file, `chflags hidden`, and
  `com.apple.FinderInfo` xattr with kIsInvisible. **Do not** use `SetFile -a V` on
  the mounted volume — causes write permission errors (-61).
- Post-mount copy of `.background` failed on read-only attach; stage everything in
  `srcfolder` instead (including `.background` + `.hidden`).
- Icon Y at ~28% of bg height leaves room for labels below icons on white bg.
