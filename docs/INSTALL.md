# Installing StudyBar

## Requirements

- macOS **14.0 (Sonoma)** or later
- For building from source: **Xcode** with Command Line Tools (`xcodebuild -runFirstLaunch` once after install)

StudyBar is ad-hoc signed (“Sign to Run Locally”). On first launch, macOS may show an unidentified-developer warning. **This is normal** for open-source Mac apps outside the App Store.

**Recommended (one time only):** Right-click **StudyBar.app** in Applications → **Open** → confirm **Open**. After that, double-click works.

Alternatives: **System Settings → Privacy & Security → Open Anyway**, or `xattr -cr /Applications/StudyBar.app`, or use the [install script](#method-2-install-script) below.

---

## Method 1: GitHub Release (recommended)

> **Do not** use **Code → Download ZIP** on the repo homepage. That is the **source code**. The app lives on the **Releases** page.

**Best for:** most users who just want the app.

1. Go to [github.com/IMisbahk/studybar/releases/latest](https://github.com/IMisbahk/studybar/releases/latest)
2. Download **`StudyBar-x.y.z.zip`**
3. Double-click the zip — inside you'll find **`StudyBar-x.y.z.dmg`** (not the repo)
4. Double-click the dmg → drag **StudyBar.app** to **Applications**
5. Launch from Applications or Spotlight

Alternatively, download **`StudyBar-x.y.z.dmg`** directly from the same Releases page.

### Verify download integrity

Each release includes `StudyBar-x.y.z.sha256`:

```bash
cd ~/Downloads
shasum -a 256 -c StudyBar-1.0.0.sha256
```

Both `StudyBar-1.0.0.zip` and `StudyBar-1.0.0.dmg` must report `OK`.

---

## Method 2: Install script

**Best for:** terminal users who want the latest release in one command.

```bash
curl -fsSL https://raw.githubusercontent.com/IMisbahk/studybar/main/scripts/install-release.sh | bash
```

Install a specific version:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IMisbahk/studybar/main/scripts/install-release.sh) 1.0.0
```

Or clone first (safer — review the script before running):

```bash
git clone https://github.com/IMisbahk/studybar.git
cd studybar
./scripts/install-release.sh
```

Installs to `/Applications/StudyBar.app`. Override destination:

```bash
INSTALL_DIR=~/Applications ./scripts/install-release.sh
```

---

## Method 3: Homebrew cask

**Best for:** Homebrew users comfortable with a local cask formula.

From a cloned repo:

```bash
git clone https://github.com/IMisbahk/studybar.git
cd studybar
brew install --cask ./packaging/homebrew/StudyBar.rb
```

The cask pins `version` and `sha256` to a specific GitHub release. Update those fields when a new version ships (see [RELEASING.md](RELEASING.md)).

---

## Method 4: Build from source

**Best for:** developers or anyone who wants to compile locally.

### Quick install (build + copy to Applications)

```bash
git clone https://github.com/IMisbahk/studybar.git
cd studybar
./scripts/install-from-source.sh
```

### Build only

```bash
./scripts/build.sh Release    # or Debug
open build/Build/Products/Release/StudyBar.app
```

### Open in Xcode

```bash
open StudyBar.xcodeproj
```

Select the **StudyBar** scheme, pick **My Mac**, press **⌘R**.

---

## Upgrading

1. Quit StudyBar (Settings → **Quit StudyBar**)
2. Install the new version using any method above (overwrites `/Applications/StudyBar.app`)
3. Relaunch — SwiftData history is preserved (stored outside the app bundle)

---

## Uninstalling

```bash
rm -rf /Applications/StudyBar.app
```

Remove local data (optional — deletes all subjects and session history):

```bash
# SwiftData default store location varies; check ~/Library/Application Support/
rm -f ~/Library/Application Support/default.store*
```

Disable launch at login if enabled: **System Settings → General → Login Items → remove StudyBar**.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| App won’t open (Gatekeeper) | Right-click → Open, or allow in Privacy & Security |
| No menu bar icon | Check the right side of the menu bar; icon is a book |
| No notifications | System Settings → Notifications → StudyBar → allow alerts |
| `xcodebuild` plugin error | Run `xcodebuild -runFirstLaunch` once |
| Launch at login fails | App may need to live in `/Applications` for `SMAppService` |
