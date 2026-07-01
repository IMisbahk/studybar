#!/usr/bin/env bash
# builds a styled DMG: background image, app + Applications folder side by side
set -euo pipefail

appPath="${1:?usage: create-dmg.sh /path/to/StudyBar.app /path/to/output.dmg}"
dmgPath="${2:?}"
rootDir="$(cd "$(dirname "$0")/../.." && pwd)"
volname="StudyBar"
staging="$(mktemp -d)"
rwDmg="${dmgPath%.dmg}-rw.dmg"
backgroundSrc="$rootDir/packaging/dmg/background.png"

trap 'rm -rf "$staging"; hdiutil detach "/Volumes/$volname" -quiet 2>/dev/null || true' EXIT

cp -R "$appPath" "$staging/StudyBar.app"
ln -s /Applications "$staging/Applications"
mkdir -p "$staging/.background"
cp "$backgroundSrc" "$staging/.background/background.png"

rm -f "$rwDmg" "$dmgPath"

# srcfolder puts everything on the volume before we tweak Finder layout
hdiutil create -volname "$volname" -srcfolder "$staging" -ov -format UDRW "$rwDmg" >/dev/null

device="$(hdiutil attach -readwrite -noverify -noautoopen "$rwDmg" | awk '/^\/dev/ {print $1; exit}')"
mountPoint="/Volumes/$volname"

chflags hidden "$mountPoint/.background" 2>/dev/null || true
SetFile -a C "$mountPoint" 2>/dev/null || true

osascript "$rootDir/packaging/dmg/configure.applescript"

sync
hdiutil detach "$device" >/dev/null
hdiutil convert "$rwDmg" -format UDZO -imagekey zlib-level=9 -o "$dmgPath" >/dev/null
rm -f "$rwDmg"

echo "==> styled dmg: $dmgPath"
