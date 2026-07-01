import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    private var calendar: Calendar { .current }

    private var todayTotal: TimeInterval {
        total(for: sessions.filter { calendar.isDateInToday($0.startedAt) })
    }

    private var weekTotal: TimeInterval {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return total(for: sessions.filter { $0.startedAt >= weekStart })
    }

    private var monthTotal: TimeInterval {
        guard let monthStart = calendar.dateInterval(of: .month, for: Date())?.start else { return 0 }
        return total(for: sessions.filter { $0.startedAt >= monthStart })
    }

    private var dailyAverage: TimeInterval {
        guard let firstDate = sessions.map(\.startedAt).min() else { return 0 }
        let dayCount = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: firstDate),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
        return total(for: sessions) / Double(max(1, dayCount + 1))
    }

    private var subjectTotals: [(name: String, duration: TimeInterval)] {
        Dictionary(grouping: sessions, by: \.subjectName)
            .map { (name: $0.key, duration: total(for: $0.value)) }
            .sorted { $0.duration > $1.duration }
    }

    private var groupedByDay: [(day: Date, sessions: [StudySession])] {
        Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.startedAt) }
            .map { (day: $0.key, sessions: $0.value.sorted { $0.startedAt > $1.startedAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.title3.bold())

            if sessions.isEmpty {
                Text("No sessions yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            } else {
                statsGrid
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(groupedByDay, id: \.day) { group in
                            dayGroup(group)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private var statsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                statCard(title: "Today", value: todayTotal)
                statCard(title: "Week", value: weekTotal)
            }
            HStack(spacing: 8) {
                statCard(title: "Month", value: monthTotal)
                statCard(title: "Daily avg", value: dailyAverage)
            }

            if !subjectTotals.isEmpty {
                Divider().padding(.vertical, 2)
                ForEach(subjectTotals, id: \.name) { entry in
                    statRow(title: entry.name, value: entry.duration, secondary: true)
                }
            }
        }
    }

    private func statCard(title: String, value: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(formatted(value))
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }

    private func statRow(title: String, value: TimeInterval, secondary: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(secondary ? .caption : .subheadline)
                .foregroundStyle(secondary ? .secondary : .primary)
            Spacer()
            Text(formatted(value))
                .font((secondary ? Font.caption : Font.subheadline).monospacedDigit())
                .foregroundStyle(secondary ? .secondary : .primary)
        }
    }

    private func dayGroup(_ group: (day: Date, sessions: [StudySession])) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dayLabel(group.day))
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(group.sessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.topicName.map { "\(session.subjectName) — \($0)" } ?? session.subjectName)
                            .font(.callout)
                        Text(session.startedAt, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !session.completed {
                        Image(systemName: "xmark.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(formatted(session.actualDuration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func total(for sessions: [StudySession]) -> TimeInterval {
        sessions.reduce(0) { $0 + $1.actualDuration }
    }

    private func formatted(_ interval: TimeInterval) -> String {
        StudyFormatting.duration(interval)
    }

    private func dayLabel(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day)
    }
}
