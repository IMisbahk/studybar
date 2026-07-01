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
  expected="$(grep "${baseName}.zip" "$tmpDir/${baseName}.sha256" | awk '{print $1}')"
  actual="$(shasum -a 256 "$tmpDir/${baseName}.zip" | awk '{print $1}')"
  if [[ "$expected" != "$actual" ]]; then
    echo "error: zip checksum mismatch" >&2
    exit 1
  fi
  echo "    checksum OK"
else
  echo "    (no checksum file on release — skipping)"
fi

echo "==> extracting zip..."
unzip -q "$tmpDir/${baseName}.zip" -d "$tmpDir"

targetPath="$installDir/StudyBar.app"
if [[ -d "$targetPath" ]]; then
  echo "==> removing existing $targetPath"
  rm -rf "$targetPath"
fi

# release zip contains the .dmg (not source code, not the .app directly)
dmgPath="$tmpDir/${baseName}.dmg"
if [[ -f "$dmgPath" ]]; then
  echo "==> mounting dmg..."
  mountPoint="$(hdiutil attach "$dmgPath" -nobrowse -quiet | tail -1 | sed 's/.*\t//')"
  trap 'hdiutil detach "$mountPoint" -quiet 2>/dev/null || true; rm -rf "$tmpDir"' EXIT
  echo "==> installing to $targetPath"
  ditto "$mountPoint/StudyBar.app" "$targetPath"
elif [[ -d "$tmpDir/StudyBar.app" ]]; then
  # fallback for older release layout
  echo "==> installing to $targetPath"
  ditto "$tmpDir/StudyBar.app" "$targetPath"
else
  echo "error: expected ${baseName}.dmg or StudyBar.app inside zip" >&2
  exit 1
fi

echo "==> installed StudyBar ${version#v}. launch with: open -a StudyBar"
