import AppKit
import CryptoKit
import Foundation

enum UpdateInstaller {
    private static let repo = "IMisbahk/studybar"
    private static let apiUrl = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
    // dashboard ⌘Q intercept blocks terminate — relauncher needs a real quit
    static var isRelaunchPending = false

    struct ReleaseAsset {
        let version: String
        let dmgUrl: URL
        let expectedSha256: String?
    }

    enum InstallState: Equatable {
        case idle
        case downloading(progress: Double)
        case ready(version: String, dmgPath: URL)
        case failed(String)
    }

    static func fetchLatestAsset() async -> ReleaseAsset? {
        do {
            var request = URLRequest(url: apiUrl)
            request.setValue("StudyBar/\(UpdateChecker.currentVersion)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String,
                  let assets = json["assets"] as? [[String: Any]] else { return nil }
            let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            guard let dmg = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
                  let dmgUrlStr = dmg["browser_download_url"] as? String,
                  let dmgUrl = URL(string: dmgUrlStr) else { return nil }
            let shaAsset = assets.first { ($0["name"] as? String)?.hasSuffix(".sha256") == true }
            let shaUrl = (shaAsset?["browser_download_url"] as? String).flatMap(URL.init(string:))
            let expectedSha = await fetchDmgSha256(from: shaUrl, version: version)
            return ReleaseAsset(version: version, dmgUrl: dmgUrl, expectedSha256: expectedSha)
        } catch {
            return nil
        }
    }

    private static func fetchDmgSha256(from url: URL?, version: String) async -> String? {
        guard let url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let text = String(decoding: data, as: UTF8.self)
            let dmgName = "StudyBar-\(version).dmg"
            for line in text.split(separator: "\n") {
                let parts = line.split(separator: " ", maxSplits: 1)
                guard parts.count == 2, parts[1].hasSuffix(dmgName) else { continue }
                return String(parts[0])
            }
        } catch {}
        return nil
    }

    static func updatesDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("StudyBar/Updates", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func installLogURL() throws -> URL {
        try updatesDirectory().appendingPathComponent("install.log")
    }

    static func download(asset: ReleaseAsset, onProgress: @escaping (Double) -> Void) async throws -> URL {
        let dest = try updatesDirectory().appendingPathComponent("StudyBar-\(asset.version).dmg")
        try? FileManager.default.removeItem(at: dest)

        let (bytes, response) = try await URLSession.shared.bytes(from: asset.dmgUrl)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "UpdateInstaller", code: 1, userInfo: [NSLocalizedDescriptionKey: "Download failed"])
        }
        let expectedLength = Double(response.expectedContentLength)
        FileManager.default.createFile(atPath: dest.path, contents: nil)
        let handle = try FileHandle(forWritingTo: dest)
        defer { try? handle.close() }

        var hasher = SHA256()
        var received: Int64 = 0
        var buffer = Data()
        buffer.reserveCapacity(64 * 1024)
        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= 64 * 1024 {
                hasher.update(data: buffer)
                handle.write(buffer)
                received += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                if expectedLength > 0 {
                    onProgress(min(1, Double(received) / expectedLength))
                }
            }
        }
        if !buffer.isEmpty {
            hasher.update(data: buffer)
            handle.write(buffer)
            received += Int64(buffer.count)
        }
        onProgress(1)

        if let expected = asset.expectedSha256 {
            let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
            guard digest.lowercased() == expected.lowercased() else {
                try? FileManager.default.removeItem(at: dest)
                throw NSError(domain: "UpdateInstaller", code: 2, userInfo: [NSLocalizedDescriptionKey: "Checksum mismatch"])
            }
        }
        return dest
    }

    @MainActor
    static func openInstaller(dmgPath: URL) {
        NSWorkspace.shared.open(dmgPath)
    }

    @MainActor
    static func installAndRelaunch(dmgPath: URL) throws {
        let mountPoint = try mountDmg(at: dmgPath)
        let sourceApp = mountPoint.appendingPathComponent("StudyBar.app")
        guard FileManager.default.fileExists(atPath: sourceApp.path) else {
            try? detachDmg(mountPoint)
            throw NSError(domain: "UpdateInstaller", code: 3, userInfo: [NSLocalizedDescriptionKey: "StudyBar.app not found in update image"])
        }

        let targetPath = installTargetPath()
        let logPath = try installLogURL().path
        let scriptURL = try writeRelauncherScript(
            sourceApp: sourceApp.path,
            targetApp: targetPath,
            mountPoint: mountPoint.path,
            logPath: logPath
        )

        // detach from parent — otherwise macOS kills the script when we quit
        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
        launcher.arguments = ["-c", "nohup \"\(scriptURL.path)\" >> \"\(logPath)\" 2>&1 &"]
        try launcher.run()
        launcher.waitUntilExit()
        guard launcher.terminationStatus == 0 else {
            throw NSError(domain: "UpdateInstaller", code: 6, userInfo: [NSLocalizedDescriptionKey: "Could not start update installer"])
        }

        isRelaunchPending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            NSApp.terminate(nil)
        }
    }

    private static func installTargetPath() -> String {
        let applications = "/Applications/StudyBar.app"
        let current = Bundle.main.bundlePath
        if current.hasPrefix("/Applications/") {
            return current
        }
        if FileManager.default.fileExists(atPath: applications) {
            return applications
        }
        return current
    }

    private static func mountDmg(at dmgPath: URL) throws -> URL {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["attach", dmgPath.path, "-nobrowse", "-plist"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "UpdateInstaller", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not mount update image"])
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let entities = plist["system-entities"] as? [[String: Any]] else {
            throw NSError(domain: "UpdateInstaller", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not read mount point"])
        }

        for entity in entities {
            if let mountPoint = entity["mount-point"] as? String {
                return URL(fileURLWithPath: mountPoint)
            }
        }
        throw NSError(domain: "UpdateInstaller", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not read mount point"])
    }

    private static func detachDmg(_ mountPoint: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["detach", mountPoint.path, "-quiet"]
        try process.run()
        process.waitUntilExit()
    }

    private static func writeRelauncherScript(sourceApp: String, targetApp: String, mountPoint: String, logPath: String) throws -> URL {
        let scriptURL = try updatesDirectory().appendingPathComponent("relaunch.sh")
        let script = """
        #!/bin/bash
        set -e
        SOURCE="\(sourceApp)"
        TARGET="\(targetApp)"
        MOUNT="\(mountPoint)"

        echo "[$(date)] update started" >> "\(logPath)"

        for _ in $(seq 1 60); do
          pgrep -x StudyBar >/dev/null || break
          sleep 0.25
        done

        ditto "$SOURCE" "$TARGET"
        xattr -cr "$TARGET" 2>/dev/null || true
        /usr/bin/hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
        /usr/bin/open "$TARGET"
        echo "[$(date)] update finished" >> "\(logPath)"
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        return scriptURL
    }
}
