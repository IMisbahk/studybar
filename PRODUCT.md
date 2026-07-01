# StudyBar — macOS Menu Bar Study Timer

## What this is
A native macOS menu bar app (like the "Claude usage" style popover apps) for running focused study sessions. Lives in the menu bar, no dock icon, no main window. Click to open a small popover, pick a subject + duration, start a session, and the menu bar icon itself turns into a live countdown with a progress ring.

## Tech stack
- Swift + SwiftUI
- `MenuBarExtra` API (macOS 13 Ventura+) for the menu bar presence
- `UserNotifications` framework for start/end alerts
- Local persistence: SwiftData (or a flat JSON file if SwiftData feels like overkill) for session history
- No backend, no network calls, fully local app

## Core flow
1. User clicks the menu bar icon (idle state: simple icon, e.g. a book or clock symbol)
2. Popover opens showing:
   - Subject picker (editable list — user can add/remove/rename subjects and topics)
   - Duration picker (presets: 25 / 50 / 90 min, plus custom input)
   - "Start Session" button
3. On tap Start:
   - A macOS notification fires confirming the session started (e.g. "Studying Maths — Quadratics for 50 minutes")
   - Popover closes (or shows a "session active" view — see below)
   - Menu bar icon **morphs**: the idle icon is replaced by a compact live countdown — timer text (e.g. `24:59`) plus a small circular progress ring around/behind an icon, animating as time elapses
4. While session is active, clicking the menu bar icon again opens a popover showing:
   - Current subject/topic
   - Time remaining (large, live-updating)
   - Progress ring (larger version of the menu bar mini one)
   - Pause / Resume button
   - Stop (end early) button
   - Extend by +5/+10 min button
5. When timer hits zero:
   - Notification fires ("Session complete — Maths, 50 min")
   - Menu bar icon reverts to idle state
   - Session is logged automatically (subject, topic, planned duration, actual duration, date/time, completed vs stopped-early flag)
6. Popover also has a lightweight "History" tab/section:
   - List of past sessions (today + recent), grouped by day
   - Basic totals: time studied today, this week, per subject breakdown

## Subject/topic model
- User-editable list, not hardcoded. Ship with an empty or minimally seeded list; user adds their own subjects (e.g. Maths, Physics, Chemistry) and can add topics under each subject (e.g. Maths → Quadratics, Complex Numbers) for more granular logging.
- Store subjects/topics + history locally, persist across launches.
- Store study sessions like [weekly] [today] [monthly] [daily-average] and things like that titled.
## Visual/animation requirements
- Menu bar icon state change (idle → countdown) should feel smooth, not an abrupt swap — a quick transition/fade is enough, doesn't need to be elaborate
- Progress ring should visibly animate/drain in real time, not just jump every minute
- Popover open/close should use standard macOS popover transition (this is mostly free from `MenuBarExtra` + `.popover`/`NSPopover` defaults)
- Keep visual style minimal/native — matching system dark/light mode automatically, no custom heavy theming

## Non-goals (v1)
- No fixed schedule/calendar-based auto-triggering — sessions are always manually started by the user
- No cloud sync, no accounts, no login
- No iOS/iPadOS companion
- No Pomodoro auto-chaining (e.g. auto-starting break timers) — can be a later addition, not v1

## Nice-to-haves (only if trivial, otherwise skip for v1)
- Menu bar right-click or secondary menu for quick actions (pause/stop without opening full popover)
- Sound option on session end (in addition to notification)
- Launch-at-login toggle in settings

## Settings (minimal)
- Toggle launch at login
- Toggle sound on session end
- Manage subject/topic list (add/edit/delete)