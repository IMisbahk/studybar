#!/usr/bin/env bash
# bumps VERSION file and syncs MARKETING_VERSION / CURRENT_PROJECT_VERSION in Xcode project
set -euo pipefail

rootDir="$(cd "$(dirname "$0")/.." && pwd)"
newVersion="${1:-}"

if [[ -z "$newVersion" ]]; then
  echo "usage: $0 <version>   e.g. 1.0.1 or 1.1.0" >&2
  exit 1
fi

if [[ ! "$newVersion" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must be semver (x.y.z)" >&2
  exit 1
fi

pbxproj="$rootDir/StudyBar.xcodeproj/project.pbxproj"

# marketing = x.y.z; build number = encoded semver (1.0.0 -> 10000)
IFS='.' read -r major minor patch <<< "$newVersion"
buildNumber=$((major * 10000 + minor * 100 + patch))

echo "$newVersion" > "$rootDir/VERSION"

sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = ${newVersion}/g" "$pbxproj"
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*/CURRENT_PROJECT_VERSION = ${buildNumber}/g" "$pbxproj"

echo "==> VERSION=$newVersion"
echo "==> MARKETING_VERSION=$newVersion, CURRENT_PROJECT_VERSION=$buildNumber"
echo "    next: update CHANGELOG.md, commit, tag v${newVersion}, push"
