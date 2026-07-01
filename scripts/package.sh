#!/usr/bin/env bash
# packages StudyBar.app into dist/ as .zip and .dmg with SHA256 checksums
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

echo "==> creating zip..."
ditto -c -k --sequesterRsrc --keepParent "$appPath" "$distDir/${baseName}.zip"

echo "==> creating dmg..."
dmgPath="$distDir/${baseName}.dmg"
rm -f "$dmgPath"
hdiutil create \
  -volname "StudyBar" \
  -srcfolder "$appPath" \
  -ov \
  -format UDZO \
  "$dmgPath" >/dev/null

echo "==> writing checksums..."
(
  cd "$distDir"
  shasum -a 256 "${baseName}.zip" "${baseName}.dmg" > "${baseName}.sha256"
)

echo "==> packaged:"
ls -lh "$distDir/${baseName}".*
