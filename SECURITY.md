# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅        |

## Reporting a vulnerability

StudyBar is a local-only macOS menu bar app with no network surface. If you find a security issue (sandbox escape, data exposure, code execution via malformed input, etc.):

1. **Do not** open a public GitHub issue for exploitable vulnerabilities
2. Email or DM the maintainer via [GitHub @IMisbahk](https://github.com/IMisbahk)
3. Include steps to reproduce and your macOS version

Expect a response within 7 days.

## Scope notes

- All data is stored locally via SwiftData on your Mac
- No telemetry, analytics, or remote APIs
- Releases are ad-hoc signed; verify checksums from `StudyBar-x.y.z.sha256` when downloading
- Install scripts (`scripts/install-release.sh`) fetch binaries only from `github.com/IMisbahk/studybar/releases`
