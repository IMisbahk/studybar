#!/usr/bin/env bash
# downloads the latest (or specified) GitHub release and installs to /Applications
set -euo pipefail

repo="${STUDYBAR_REPO:-IMisbahk/studybar}"
installDir="${INSTALL_DIR:-/Applications}"
version="${1:-}"

if [[ -z "$version" ]]; then
  echo "==> fetching latest release..."
  version="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))")"
fi

tag="v${version#v}"
baseName="StudyBar-${version#v}"
zipUrl="https://github.com/${repo}/releases/download/${tag}/${baseName}.zip"
tmpDir="$(mktemp -d)"
trap 'rm -rf "$tmpDir"' EXIT

echo "==> downloading ${tag} from ${repo}..."
curl -fsSL "$zipUrl" -o "$tmpDir/${baseName}.zip"

echo "==> verifying checksum (optional)..."
checksumUrl="https://github.com/${repo}/releases/download/${tag}/${baseName}.sha256"
if curl -fsSL "$checksumUrl" -o "$tmpDir/${baseName}.sha256" 2>/dev/null; then
  (cd "$tmpDir" && shasum -a 256 -c "${baseName}.sha256")
else
  echo "    (no checksum file on release — skipping)"
fi

echo "==> extracting..."
unzip -q "$tmpDir/${baseName}.zip" -d "$tmpDir"

targetPath="$installDir/StudyBar.app"
if [[ -d "$targetPath" ]]; then
  echo "==> removing existing $targetPath"
  rm -rf "$targetPath"
fi

echo "==> installing to $targetPath"
ditto "$tmpDir/StudyBar.app" "$targetPath"

echo "==> installed StudyBar ${version#v}. launch with: open -a StudyBar"
