# Releasing StudyBar

Releases follow [Semantic Versioning](https://semver.org/) and are automated via GitHub Actions.

## Checklist

1. **Bump version**
   ```bash
   ./scripts/bump-version.sh 2.14.0
   ```

2. **Update [CHANGELOG.md](../CHANGELOG.md)**
   - Add a `## [2.14.0] - YYYY-MM-DD` section at the top
   - List changes under Added / Changed / Fixed / Removed
   - Optional: add `release/RELEASE_NOTES_v2.14.0.md` for the GitHub release body

3. **Update Homebrew cask**
   ```bash
   ./scripts/package.sh Release
   ./scripts/update-homebrew-cask.sh
   ```

4. **Commit**
   ```bash
   git add VERSION CHANGELOG.md StudyBar.xcodeproj/project.pbxproj packaging/homebrew/StudyBar.rb release/
   git commit -m "chore: release v2.14.0"
   ```

5. **Tag and push**
   ```bash
   git tag v2.14.0
   git push origin main --tags
   ```

6. **GitHub Actions** builds and publishes:
   - `StudyBar-2.14.0.zip`
   - `StudyBar-2.14.0.dmg`
   - `StudyBar-2.14.0.sha256`

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
| `VERSION` | `2.13.5` |
| `project.pbxproj` | `MARKETING_VERSION = 2.13.5` |
| `project.pbxproj` | `CURRENT_PROJECT_VERSION = 21305` (encoded: major×10000 + minor×100 + patch) |
| Git tag | `v2.13.5` |
| Release assets | `StudyBar-2.13.5.zip` etc. |

Encoding: `2.13.5` → `2×10000 + 13×100 + 5` = `21305`.

## Pre-release validation

```bash
./scripts/build.sh Release
open build/Build/Products/Release/StudyBar.app
# smoke test: start session, history, dashboard, settings, quit
./scripts/package.sh Release
shasum -a 256 -c dist/StudyBar-*.sha256
```

## Branch naming

CI triggers on `main`. Default branch is `main`.
