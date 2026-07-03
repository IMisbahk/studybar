import AppKit
import Foundation

enum FeedbackService {
    private static let repo = "IMisbahk/studybar"

    struct GitHubSummary: Decodable {
        let stargazersCount: Int

        enum CodingKeys: String, CodingKey {
            case stargazersCount = "stargazers_count"
        }
    }

    // github stars — public social proof, not user star ratings
    static func fetchGitHubStars() async -> Int? {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)") else { return nil }
        do {
            var request = URLRequest(url: url)
            request.setValue("StudyBar/\(UpdateChecker.currentVersion)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let summary = try JSONDecoder().decode(GitHubSummary.self, from: data)
            return summary.stargazersCount
        } catch {
            return nil
        }
    }

    // opens a pre-filled github issue — that's where rating feedback lands for now
    @MainActor
    static func submitRating(_ stars: Int, appVersion: String) {
        let title = "App rating: \(stars)/5"
        let body = """
        StudyBar version: \(appVersion)
        Rating: \(stars)/5

        (Optional — tell us what you love or what to improve)
        """
        guard let url = feedbackURL(title: title, body: body) else { return }
        NSWorkspace.shared.open(url)

        if stars >= 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let starUrl = URL(string: "https://github.com/\(repo)") {
                    NSWorkspace.shared.open(starUrl)
                }
            }
        }
    }

    private static func feedbackURL(title: String, body: String) -> URL? {
        var components = URLComponents(string: "https://github.com/\(repo)/issues/new")
        components?.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "body", value: body),
        ]
        return components?.url
    }
}
