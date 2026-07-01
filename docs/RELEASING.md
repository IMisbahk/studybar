# Releasing StudyBar

Releases follow [Semantic Versioning](https://semver.org/) and are automated via GitHub Actions.

## Checklist

1. **Bump version**
   ```bash
   ./scripts/bump-version.sh 1.1.0
   ```

2. **Update [CHANGELOG.md](../CHANGELOG.md)**
   - Add a `## [1.1.0] - YYYY-MM-DD` section under `## [Unreleased]` or at the top
   - List changes under Added / Changed / Fixed / Removed

3. **Update Homebrew cask**
   ```bash
   ./scripts/package.sh Release
   ./scripts/update-homebrew-cask.sh
   ```

4. **Commit**
   ```bash
   git add VERSION CHANGELOG.md StudyBar.xcodeproj/project.pbxproj packaging/homebrew/StudyBar.rb
   git commit -m "chore: release v1.1.0"
   ```

5. **Tag and push**
   ```bash
   git tag v1.1.0
   git push origin main --tags
   ```
   (Use `master` if that’s your default branch.)

6. **GitHub Actions** builds and publishes:
   - `StudyBar-1.1.0.zip`
   - `StudyBar-1.1.0.dmg`
   - `StudyBar-1.1.0.sha256`

   Monitor: **Actions** tab → **Release** workflow.

## Local release (without CI)

```bash
./scripts/package.sh Release
ls -lh dist/
```

Upload `dist/StudyBar-*` manually via **GitHub → Releases → Draft a new release**.

## Version file sync

| File | Field |
|------|-------|
| `VERSION` | `1.0.0` |
| `project.pbxproj` | `MARKETING_VERSION = 1.0.0` |
| `project.pbxproj` | `CURRENT_PROJECT_VERSION = 10000` (encoded: major×10000 + minor×100 + patch) |
| Git tag | `v1.0.0` |
| Release assets | `StudyBar-1.0.0.zip` etc. |

## Pre-release validation

```bash
./scripts/build.sh Release
open build/Build/Products/Release/StudyBar.app
# smoke test: start session, history, settings, quit
./scripts/package.sh Release
shasum -a 256 -c dist/StudyBar-*.sha256
```

## Branch naming

CI triggers on both `main` and `master`. Prefer renaming to `main` before the first public push:

```bash
git branch -m master main
```
