import AppKit
import CryptoKit
import Foundation

enum UpdateInstaller {
    private static let repo = "IMisbahk/studybar"
    private static let apiUrl = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!

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
}
