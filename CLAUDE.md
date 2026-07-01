# StudyBar — session notes

## Environment constraints (this sandbox, may not apply to your actual Mac)
- No full Xcode installed here, only Command Line Tools - and CLT's `swift-frontend` is
  itself broken (dyld: missing `lib_CompilerSwiftIDEUtils.dylib`). Could not run
  `xcodebuild`, `swiftc`, or even `swift --version` in this environment.
- The `.xcodeproj` was hand-written (no `xcodegen`/Xcode project wizard available,
  and didn't want to add xcodegen as a dependency without asking first).
- Verification used instead: `plutil -convert json` on `project.pbxproj` + a small
  Python script that walks the object graph checking every UUID reference resolves
  and every registered `.swift` file is actually in the Sources build phase. This
  catches structural mistakes (dangling refs, files not added to build phase) but
  NOT actual Swift compile errors. **First thing to do in Xcode: Cmd+B and fix
  whatever that surfaces** - treat this build as unverified until then.
- If you (future agent) also land in a sandbox without real Xcode, don't burn time
  trying to fix the CLT install (needs sudo + big download) - just hand-edit the
  pbxproj carefully and lean on the validation script approach above.

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

## Architecture
- `Core/SessionManager.swift` - the whole state machine (idle/running/paused),
  1s repeating `Timer`, owns the `ModelContext` and logs a `StudySession` on both
  natural completion and early stop (`completed` flag distinguishes them).
- `Views/PopoverRootView.swift` - switches Timer/History/Settings tabs, and within
  the Timer tab switches Idle vs Active based on `sessionManager.phase`.
- Settings' "Manage Subjects" uses `NavigationStack`/`NavigationLink`, deliberately
  NOT `.sheet` - sheets are known to be unreliable inside `MenuBarExtra(.window)`
  popovers (no real host NSWindow to attach to).
- `@Observable` (Observation framework) throughout, not `ObservableObject` -
  `SessionManager` is injected via `.environment(sessionManager)` for the popover
  content, but passed as a plain property to `MenuBarLabelView` since the label
  closure is a separate view hierarchy that doesn't inherit that `.environment()`.

## Things to visually check once it's running (couldn't verify without Xcode)
- `ManageSubjectsView`: `TextField` for renaming is embedded inside a
  `DisclosureGroup` label - possible click could both focus the field and toggle
  expand/collapse. Works in theory, want eyes on it.
- Menu bar label (icon + ring + `mm:ss`) foreground color/contrast in both light
  and dark menu bar - it's a custom composite view, not a single template `Image`,
  so it doesn't get automatic menu-bar vibrancy the way a plain SF Symbol would.

## Permissions used this session
- Ran `git init` + initial commit without asking (per standing instruction when repo
  is missing). No destructive commands, no new dependencies installed, nothing
  pushed anywhere.

## DMG packaging notes (2026-07-01)
- `packaging/dmg/background.png` is **600×400**, white bg, black arrow + instruction text.
  Window bounds in `configure.applescript` are derived from PNG dimensions.
- Hide `.background` folder three ways: `/.hidden` file, `chflags hidden`, and
  `com.apple.FinderInfo` xattr with kIsInvisible. **Do not** use `SetFile -a V` on
  the mounted volume — causes write permission errors (-61).
- Post-mount copy of `.background` failed on read-only attach; stage everything in
  `srcfolder` instead (including `.background` + `.hidden`).
- Icon Y at ~28% of bg height leaves room for labels below icons on white bg.
- v1.1.2 tagged locally, not pushed to GitHub as of this session.
