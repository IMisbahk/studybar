import SwiftUI
import SwiftData

struct GalaxyView: View {
    @Query(sort: \SubjectProgress.totalStudySeconds, order: .reverse) private var subjectRows: [SubjectProgress]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your study galaxy grows as you learn.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if subjectRows.isEmpty {
                    ContentUnavailableView(
                        "No Planets Yet",
                        systemImage: "globe.americas.fill",
                        description: Text("Complete sessions to grow a planet for each subject.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 280)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 16)], spacing: 20) {
                        ForEach(subjectRows, id: \.persistentModelID) { row in
                            planetCard(row)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.05, blue: 0.12), Color(red: 0.08, green: 0.06, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Galaxy")
    }

    private func planetCard(_ row: SubjectProgress) -> some View {
        let hours = row.totalStudySeconds / 3600
        let tier = PlanetTier.from(hours: hours)
        return VStack(spacing: 10) {
            PlanetView(subjectName: row.subjectName, hours: hours, tier: tier)
            Text(row.subjectName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("\(tier.title) · \(StudyFormatting.duration(row.totalStudySeconds))")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }
}
