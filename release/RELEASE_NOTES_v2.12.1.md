# StudyBar 2.12.1 — Smoother first launch

Less System Settings hunting. Permissions are optional and only asked when you want them.

## What's new

### Permissions only when you opt in
- **No notification prompt on startup** — asked only if you enable notifications in onboarding or turn on reminders
- **Global keyboard shortcuts (⌥⌘) are optional** — off by default; shortcuts still work while the menu bar popover is open
- Onboarding **Skip for Now** on the permissions step — app is fully usable without granting anything

### Settings clarity
- Toggle for global shortcuts with live status
- One-tap **Open Accessibility Settings** only if you enabled global shortcuts but haven't granted access yet

## First install — macOS may block the app once

StudyBar is distributed outside the App Store and is **not notarized** (that requires a paid Apple Developer account). The first time you open it, macOS may say the app can't be checked for malware. **This is normal** for indie Mac apps.

**Easiest fix (one time only):**

1. Open **Applications** in Finder
2. **Right-click** `StudyBar.app` → **Open**
3. Click **Open** in the dialog

After that, double-click works forever. No need to dig through System Settings unless you prefer **Privacy & Security → Open Anyway**.

**Terminal alternative:** `xattr -cr /Applications/StudyBar.app`

**Install script** (strips quarantine automatically):

```bash
curl -fsSL https://raw.githubusercontent.com/IMisbahk/studybar/main/scripts/install-release.sh | bash
```

StudyBar lives in the **menu bar** (book icon) — there is no Dock icon.

## Upgrade from 2.12.0

Download the DMG, replace the app in Applications, or use in-app update when idle.
