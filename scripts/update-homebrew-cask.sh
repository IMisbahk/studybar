#!/usr/bin/env bash
# updates packaging/homebrew/StudyBar.rb version + sha256 from dist/
set -euo pipefail

rootDir="$(cd "$(dirname "$0")/.." && pwd)"
version="$(tr -d '[:space:]' < "$rootDir/VERSION")"
shaFile="$rootDir/dist/StudyBar-${version}.sha256"
caskFile="$rootDir/packaging/homebrew/StudyBar.rb"

if [[ ! -f "$shaFile" ]]; then
  echo "error: run ./scripts/package.sh first — missing $shaFile" >&2
  exit 1
fi

zipHash="$(grep '\.zip' "$shaFile" | awk '{print $1}')"

sed -i '' "s/version \"[^\"]*\"/version \"${version}\"/" "$caskFile"
sed -i '' "s/sha256 \"[^\"]*\"/sha256 \"${zipHash}\"/" "$caskFile"

echo "==> updated $caskFile"
echo "    version=$version sha256=$zipHash"
