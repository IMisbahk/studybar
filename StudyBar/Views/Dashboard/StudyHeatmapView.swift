import SwiftUI

struct StudyHeatmapView: View {
    let days: [DayStudyTotal]
    var showLegend: Bool = true

    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    private var calendar: Calendar { .current }

    private var weeks: [[DayStudyTotal?]] {
        guard let first = days.first?.date else { return [] }
        let weekday = calendar.component(.weekday, from: first)
        let leadingBlanks = (weekday - calendar.firstWeekday + 7) % 7
        var padded: [DayStudyTotal?] = Array(repeating: nil, count: leadingBlanks)
        padded.append(contentsOf: days.map { Optional($0) })
        while padded.count % 7 != 0 { padded.append(nil) }
        return stride(from: 0, to: padded.count, by: 7).map { index in
            Array(padded[index..<min(index + 7, padded.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: cellSpacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { row in
                            cellView(week.indices.contains(row) ? week[row] : nil)
                        }
                    }
                }
            }
            if showLegend {
                HStack(spacing: 6) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(0..<5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color(for: level))
                            .frame(width: 12, height: 12)
                    }
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(_ day: DayStudyTotal?) -> some View {
        if let day {
            RoundedRectangle(cornerRadius: 2)
                .fill(color(for: day.level))
                .frame(width: cellSize, height: cellSize)
                .help("\(day.date.formatted(date: .abbreviated, time: .omitted)): \(StudyFormatting.duration(day.totalSeconds))")
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(.clear)
                .frame(width: cellSize, height: cellSize)
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0: Color(nsColor: .quaternaryLabelColor).opacity(0.25)
        case 1: Color.green.opacity(0.35)
        case 2: Color.green.opacity(0.55)
        case 3: Color.green.opacity(0.75)
        default: Color.green.opacity(0.95)
        }
    }
}
