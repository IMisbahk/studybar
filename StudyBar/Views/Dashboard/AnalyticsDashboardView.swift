import Charts
import SwiftUI
import SwiftData

struct AnalyticsDashboardView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var heatmapRange: HeatmapRange = .annual

    private var dailyTotals: [DayStudyTotal] {
        AnalyticsEngine.dailyTotals(from: sessions, range: heatmapRange)
    }

    private var heatmapDayDetails: [Date: DayStudyDetail] {
        AnalyticsEngine.dayDetails(from: sessions, range: heatmapRange)
    }

    private var weeklyTotals: [WeekStudyTotal] {
        AnalyticsEngine.weeklyTotals(from: sessions, trailingWeeks: 12)
    }

    private var subjectTotals: [SubjectStudyTotal] {
        AnalyticsEngine.subjectTotals(from: sessions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                streakRow
                heatmapCard
                weeklyChartCard
                if !subjectTotals.isEmpty {
                    subjectChartCard
                }
                exportRow
            }
            .padding(24)
        }
        .navigationTitle("Analytics")
    }

    private var streakRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Current Streak", value: "\(AnalyticsEngine.currentStreak(from: sessions)) days", icon: "flame.fill")
            statCard(title: "Longest Streak", value: "\(AnalyticsEngine.longestStreak(from: sessions)) days", icon: "trophy.fill")
            statCard(title: "Total Sessions", value: "\(sessions.count)", icon: "list.number")
            statCard(title: "Notes Saved", value: "\(AnalyticsEngine.sessionsWithNotes(from: sessions).count)", icon: "note.text")
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Study Heatmap")
                    .font(.headline)
                Text(heatmapRange.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Picker(selection: $heatmapRange) {
                ForEach(HeatmapRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            } label: { EmptyView() }
            .labelsHidden()
            .pickerStyle(.segmented)
            StudyHeatmapView(days: dailyTotals, dayDetails: heatmapDayDetails, range: heatmapRange)
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Study Time")
                .font(.headline)
            Chart(weeklyTotals) { week in
                BarMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", week.totalSeconds / 60)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
            .chartYAxisLabel("Minutes")
            .frame(height: 200)
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var subjectChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time by Subject")
                .font(.headline)
            Chart(subjectTotals.prefix(8)) { item in
                BarMark(
                    x: .value("Minutes", item.totalSeconds / 60),
                    y: .value("Subject", item.name)
                )
                .foregroundStyle(Color.mint.gradient)
            }
            .frame(height: min(280, CGFloat(subjectTotals.prefix(8).count) * 32 + 40))
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var exportRow: some View {
        HStack(spacing: 10) {
            Button("Export Heatmap PNG") {
                let exportView = VStack(alignment: .leading, spacing: 8) {
                    Text("StudyBar Study Heatmap — \(heatmapRange.title)")
                        .font(.headline)
                    StudyHeatmapView(days: dailyTotals, dayDetails: heatmapDayDetails, range: heatmapRange, showLegend: true)
                }
                .padding(16)
                .background(Color.white)
                let width: CGFloat = heatmapRange == .weekly ? 360 : 900
                ExportService.savePNG(from: exportView, size: CGSize(width: width, height: 180), defaultName: "studybar-heatmap-\(heatmapRange.rawValue).png")
            }
            Button("Export Sessions CSV") {
                ExportService.exportSessionsCSV(sessions)
            }
        }
    }
}
