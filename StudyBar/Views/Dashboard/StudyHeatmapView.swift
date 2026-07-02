import SwiftUI

struct StudyHeatmapView: View {
    let days: [DayStudyTotal]
    var range: HeatmapRange = .annual
    var showLegend: Bool = true

    private let cellSpacing: CGFloat = 3
    private var calendar: Calendar { .current }

    private var cellSize: CGFloat {
        switch range {
        case .weekly: 28
        case .monthly: 18
        case .ytd, .annual: 12
        }
    }

    private var weeks: [[DayStudyTotal?]] {
        guard !days.isEmpty else { return [] }
        if range == .weekly {
            return [days.map { Optional($0) }]
        }

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
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        if range != .weekly {
                            weekdayLabels
                        }
                        ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7, id: \.self) { row in
                                    cellView(week.indices.contains(row) ? week[row] : nil)
                                }
                            }
                            .id(index)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onAppear {
                    scrollToLatest(proxy)
                }
                .onChange(of: days.count) { _, _ in
                    scrollToLatest(proxy)
                }
            }
            if showLegend {
                legend
            }
        }
    }

    private var weekdayLabels: some View {
        let symbols = calendar.shortWeekdaySymbols
        let ordered = (0..<7).map { offset in
            symbols[(calendar.firstWeekday - 1 + offset) % 7]
        }
        return VStack(spacing: cellSpacing) {
            ForEach(ordered, id: \.self) { label in
                Text(label.prefix(1).uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 12, height: cellSize)
            }
        }
    }

    private var legend: some View {
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

    @ViewBuilder
    private func cellView(_ day: DayStudyTotal?) -> some View {
        if let day {
            RoundedRectangle(cornerRadius: 3)
                .fill(color(for: day.level))
                .frame(width: cellSize, height: cellSize)
                .overlay {
                    if range == .weekly {
                        Text(shortDayLabel(day.date))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(day.level > 1 ? .white : .secondary)
                    }
                }
                .help("\(day.date.formatted(date: .abbreviated, time: .omitted)): \(StudyFormatting.duration(day.totalSeconds))")
        } else {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(0.04))
                .frame(width: cellSize, height: cellSize)
        }
    }

    private func shortDayLabel(_ date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        let symbols = calendar.shortWeekdaySymbols
        return String(symbols[weekday - 1].prefix(1))
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        guard let lastIndex = weeks.indices.last else { return }
        DispatchQueue.main.async {
            proxy.scrollTo(lastIndex, anchor: .trailing)
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0: Color.primary.opacity(0.08)
        case 1: Color.green.opacity(0.55)
        case 2: Color.green.opacity(0.72)
        case 3: Color.green.opacity(0.88)
        default: Color(red: 0.1, green: 0.75, blue: 0.35)
        }
    }
}
