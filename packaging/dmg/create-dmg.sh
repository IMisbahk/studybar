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

bgW="$(sips -g pixelWidth "$backgroundSrc" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
bgH="$(sips -g pixelHeight "$backgroundSrc" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
appX=$((bgW * 20 / 100))
appsX=$((bgW * 66 / 100))
iconY=$((bgH * 28 / 100))

trap 'rm -rf "$staging"; hdiutil detach "/Volumes/$volname" -quiet 2>/dev/null || true' EXIT

cp -R "$appPath" "$staging/StudyBar.app"
ln -s /Applications "$staging/Applications"
mkdir -p "$staging/.background"
cp "$backgroundSrc" "$staging/.background/background.png"
chflags hidden "$staging/.background" 2>/dev/null || true
# kIsInvisible in FinderInfo — keeps .background out of the dmg window
xattr -w com.apple.FinderInfo "0000000000000000040000000000000000000000000000000000000000000000" "$staging/.background" 2>/dev/null || true

# tells Finder to never show these in the dmg window
printf '%s\n' '.background' '.fseventsd' '.DS_Store' >"$staging/.hidden"

rm -f "$rwDmg" "$dmgPath"
hdiutil detach "/Volumes/$volname" -quiet 2>/dev/null || true

hdiutil create -volname "$volname" -srcfolder "$staging" -ov -format UDRW "$rwDmg" >/dev/null

device="$(hdiutil attach -readwrite -noverify -noautoopen "$rwDmg" | awk '/^\/dev/ {print $1; exit}')"
mountPoint="/Volumes/$volname"

chflags hidden "$mountPoint/.background" 2>/dev/null || true
xattr -w com.apple.FinderInfo "0000000000000000040000000000000000000000000000000000000000000000" "$mountPoint/.background" 2>/dev/null || true
rm -rf "$mountPoint/.fseventsd" "$mountPoint/.DS_Store" 2>/dev/null || true
SetFile -a C "$mountPoint" 2>/dev/null || true

osascript "$rootDir/packaging/dmg/configure.applescript" "$bgW" "$bgH" "$appX" "$iconY" "$appsX" "$iconY"

rm -rf "$mountPoint/.fseventsd" 2>/dev/null || true
chflags hidden "$mountPoint/.background" 2>/dev/null || true
xattr -w com.apple.FinderInfo "0000000000000000040000000000000000000000000000000000000000000000" "$mountPoint/.background" 2>/dev/null || true

sync
hdiutil detach "$device" >/dev/null
hdiutil convert "$rwDmg" -format UDZO -imagekey zlib-level=9 -o "$dmgPath" >/dev/null
rm -f "$rwDmg"

echo "==> styled dmg: $dmgPath (${bgW}x${bgH}, icons at ${appX}/${appsX},${iconY})"
