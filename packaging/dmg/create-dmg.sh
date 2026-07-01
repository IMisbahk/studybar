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

# read background dimensions — window + icon layout derived from these
bgW="$(sips -g pixelWidth "$backgroundSrc" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
bgH="$(sips -g pixelHeight "$backgroundSrc" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
# icon positions: ~22% and ~72% across, vertically centered in content area
appX=$((bgW * 22 / 100))
appsX=$((bgW * 68 / 100))
iconY=$((bgH * 38 / 100))

trap 'rm -rf "$staging"; hdiutil detach "/Volumes/$volname" -quiet 2>/dev/null || true' EXIT

cp -R "$appPath" "$staging/StudyBar.app"
ln -s /Applications "$staging/Applications"
mkdir -p "$staging/.background"
cp "$backgroundSrc" "$staging/.background/background.png"

rm -f "$rwDmg" "$dmgPath"

hdiutil create -volname "$volname" -srcfolder "$staging" -ov -format UDRW "$rwDmg" >/dev/null

device="$(hdiutil attach -readwrite -noverify -noautoopen "$rwDmg" | awk '/^\/dev/ {print $1; exit}')"
mountPoint="/Volumes/$volname"

# hide junk that macOS loves to spew onto fresh volumes
chflags hidden "$mountPoint/.background" 2>/dev/null || true
rm -rf "$mountPoint/.fseventsd" "$mountPoint/.DS_Store" 2>/dev/null || true
SetFile -a C "$mountPoint" 2>/dev/null || true

osascript "$rootDir/packaging/dmg/configure.applescript" "$bgW" "$bgH" "$appX" "$iconY" "$appsX" "$iconY"

# .fseventsd respawns sometimes — nuke it again before we seal the dmg
rm -rf "$mountPoint/.fseventsd" 2>/dev/null || true
chflags hidden "$mountPoint/.background" 2>/dev/null || true

sync
hdiutil detach "$device" >/dev/null
hdiutil convert "$rwDmg" -format UDZO -imagekey zlib-level=9 -o "$dmgPath" >/dev/null
rm -f "$rwDmg"

echo "==> styled dmg: $dmgPath (${bgW}x${bgH}, icons at ${appX}/${appsX},${iconY})"
