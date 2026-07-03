#!/usr/bin/env bash
# signs StudyBar.app with Developer ID and notarizes + staples the release dmg
# requires env: DEVELOPER_ID_APPLICATION, APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD, TEAM_ID
set -euo pipefail

rootDir="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-Release}"
version="$(tr -d '[:space:]' < "$rootDir/VERSION")"
appPath="$rootDir/build/Build/Products/$configuration/StudyBar.app"
dmgPath="$rootDir/dist/StudyBar-${version}.dmg"
entitlements="$rootDir/StudyBar/StudyBar.entitlements"

: "${DEVELOPER_ID_APPLICATION:?set DEVELOPER_ID_APPLICATION (e.g. 'Developer ID Application: Your Name (TEAMID)')}"
: "${APPLE_ID:?set APPLE_ID}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?set APPLE_APP_SPECIFIC_PASSWORD}"
: "${TEAM_ID:?set TEAM_ID}"

if [[ ! -d "$appPath" ]]; then
  echo "error: build the app first: ./scripts/build.sh $configuration" >&2
  exit 1
fi

echo "==> signing app (hardened runtime)..."
codesign --force --deep --options runtime \
  --entitlements "$entitlements" \
  --sign "$DEVELOPER_ID_APPLICATION" \
  "$appPath"

echo "==> verifying signature..."
codesign --verify --deep --strict --verbose=2 "$appPath"
spctl --assess --type execute --verbose=2 "$appPath" || true

echo "==> packaging dmg..."
"$rootDir/scripts/package.sh" "$configuration"

echo "==> notarizing $dmgPath (this can take a few minutes)..."
xcrun notarytool submit "$dmgPath" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait

echo "==> stapling notarization ticket..."
xcrun stapler staple "$dmgPath"

# rebuild zip + checksums after staple
distDir="$rootDir/dist"
baseName="StudyBar-${version}"
rm -f "$distDir/${baseName}.zip" "$distDir/${baseName}.sha256"
(cd "$distDir" && zip -X -j "${baseName}.zip" "${baseName}.dmg")
(
  cd "$distDir"
  shasum -a 256 "${baseName}.dmg" "${baseName}.zip" > "${baseName}.sha256"
)

echo "==> notarized release ready in dist/"
