#!/usr/bin/env bash
# builds StudyBar.app into ./build/Build/Products/Release/ (or Debug)
set -euo pipefail

rootDir="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-Release}"
derivedDataPath="${rootDir}/build"

cd "$rootDir"

if ! xcodebuild -version &>/dev/null; then
  echo "error: xcodebuild not found. Install Xcode and run: xcodebuild -runFirstLaunch" >&2
  exit 1
fi

echo "==> building StudyBar ($configuration)..."
xcodebuild \
  -project StudyBar.xcodeproj \
  -scheme StudyBar \
  -configuration "$configuration" \
  -derivedDataPath "$derivedDataPath" \
  build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES

appPath="$derivedDataPath/Build/Products/$configuration/StudyBar.app"
if [[ ! -d "$appPath" ]]; then
  echo "error: build succeeded but app not found at $appPath" >&2
  exit 1
fi

echo "==> built: $appPath"
