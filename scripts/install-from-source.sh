#!/usr/bin/env bash
# builds from source and copies StudyBar.app to /Applications
set -euo pipefail

rootDir="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-Release}"
installDir="${INSTALL_DIR:-/Applications}"

cd "$rootDir"
"$rootDir/scripts/build.sh" "$configuration"

appPath="$rootDir/build/Build/Products/$configuration/StudyBar.app"
targetPath="$installDir/StudyBar.app"

if [[ -d "$targetPath" ]]; then
  echo "==> removing existing $targetPath"
  rm -rf "$targetPath"
fi

echo "==> installing to $targetPath"
ditto "$appPath" "$targetPath"

echo "==> done. launch with: open -a StudyBar"
