#!/usr/bin/env bash
# packages StudyBar into dist/:
#   StudyBar-x.y.z.dmg          — disk image (drag app to Applications)
#   StudyBar-x.y.z.zip          — zip containing ONLY the .dmg (like Claude Usage releases)
#   StudyBar-x.y.z.sha256       — checksums for both
set -euo pipefail

rootDir="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-Release}"

cd "$rootDir"
"$rootDir/scripts/build.sh" "$configuration"

version="$(tr -d '[:space:]' < "$rootDir/VERSION")"
appPath="$rootDir/build/Build/Products/$configuration/StudyBar.app"
distDir="$rootDir/dist"
baseName="StudyBar-${version}"

mkdir -p "$distDir"
rm -f "$distDir/${baseName}.zip" "$distDir/${baseName}.dmg" "$distDir/${baseName}.sha256"

echo "==> creating dmg..."
dmgPath="$distDir/${baseName}.dmg"
hdiutil create \
  -volname "StudyBar" \
  -srcfolder "$appPath" \
  -ov \
  -format UDZO \
  "$dmgPath" >/dev/null

echo "==> creating zip (dmg inside, not source code)..."
# -j flattens so unzip gives StudyBar-x.y.z.dmg at the top level
(cd "$distDir" && zip -X -j "${baseName}.zip" "${baseName}.dmg")

echo "==> writing checksums..."
(
  cd "$distDir"
  shasum -a 256 "${baseName}.zip" "${baseName}.dmg" > "${baseName}.sha256"
)

echo "==> packaged:"
ls -lh "$distDir/${baseName}".*
echo "==> zip contents:"
unzip -l "$distDir/${baseName}.zip"
