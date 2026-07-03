import SwiftUI

struct FeedbackRatingView: View {
    @AppStorage("submittedRatingStars") private var submittedStars = 0
    @State private var hoverStars = 0
    @State private var githubStars: Int?
    @State private var thankYou = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enjoying StudyBar?")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: filled(star) ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundStyle(filled(star) ? .yellow : .secondary)
                        .onTapGesture { rate(star) }
                        .onContinuousHover { phase in
                            switch phase {
                            case .active: hoverStars = star
                            case .ended: hoverStars = 0
                            }
                        }
                }
            }

            if thankYou || submittedStars > 0 {
                Text("Thanks for the feedback!")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Tap a star to send quick feedback on GitHub.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let githubStars {
                Text("\(githubStars) GitHub stars")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            githubStars = await FeedbackService.fetchGitHubStars()
        }
    }

    private func filled(_ star: Int) -> Bool {
        let active = hoverStars > 0 ? hoverStars : max(submittedStars, 0)
        return star <= active
    }

    private func rate(_ stars: Int) {
        submittedStars = stars
        thankYou = true
        FeedbackService.submitRating(stars, appVersion: appVersion)
    }
}
