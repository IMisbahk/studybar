# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 2.13.x  | ✅        |
| 2.12.x  | ✅        |
| 2.0.x   | ✅        |
| < 2.0   | ❌        |

## Reporting a vulnerability

StudyBar is a local-only macOS menu bar app. Network use is limited to optional GitHub release checks for in-app updates. If you find a security issue (sandbox escape, data exposure, code execution via malformed input, etc.):

1. **Do not** open a public GitHub issue for exploitable vulnerabilities
2. Contact the maintainer via [GitHub @IMisbahk](https://github.com/IMisbahk)
3. Include steps to reproduce and your macOS version

Expect a response within 7 days.

## Scope notes

- All study data is stored locally via SwiftData at `~/Library/Application Support/StudyBar/`
- No telemetry, analytics, or third-party APIs
- Releases are ad-hoc signed; verify checksums from `StudyBar-x.y.z.sha256` when downloading
- Install scripts (`scripts/install-release.sh`) fetch binaries only from `github.com/IMisbahk/studybar/releases`
