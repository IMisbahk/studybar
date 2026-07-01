import Foundation

enum UpdateChecker {
    private static let repo = "IMisbahk/studybar"
    private static let apiUrl = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(latest: String, url: URL)
        case failed
    }

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    static func check() async -> Status {
        do {
            var request = URLRequest(url: apiUrl)
            request.setValue("StudyBar/\(currentVersion)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .failed
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let tag = json?["tag_name"] as? String else { return .failed }
            let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            let htmlUrl = (json?["html_url"] as? String).flatMap(URL.init(string:))
                ?? URL(string: "https://github.com/\(repo)/releases/latest")!
            if isVersion(latest, newerThan: currentVersion) {
                return .updateAvailable(latest: latest, url: htmlUrl)
            }
            return .upToDate
        } catch {
            return .failed
        }
    }

    private static func isVersion(_ a: String, newerThan b: String) -> Bool {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }
        let count = max(aParts.count, bParts.count)
        for i in 0..<count {
            let av = i < aParts.count ? aParts[i] : 0
            let bv = i < bParts.count ? bParts[i] : 0
            if av != bv { return av > bv }
        }
        return false
    }
}
