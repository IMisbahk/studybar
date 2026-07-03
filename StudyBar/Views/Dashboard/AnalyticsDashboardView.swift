import SwiftUI
import SwiftData
import Charts

struct AnalyticsDashboardView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @Query(sort: \AchievementUnlock.unlockedAt, order: .reverse) private var achievements: [AchievementUnlock]
    @State private var heatmapRange: HeatmapRange = .annual
    @State private var exportToast: ExportResult?
    @State private var selectedWeek: Date?
    @State private var selectedDay: Date?
    @State private var selectedMonth: Date?
    @State private var selectedHour: Int?
    @State private var snapshot = AnalyticsSnapshot.build(from: [], heatmapRange: .annual)

    private var snapshotKey: String {
        let latest = sessions.first?.startedAt.timeIntervalSince1970 ?? 0
        return "\(sessions.count)-\(heatmapRange.rawValue)-\(latest)"
    }

    var body: some View {
        VStack(spacing: 0) {
            pinnedHeader
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    overviewGrid
                    scoresRow
                    comparisonRow
                    heatmapCard
                    dailyChartCard
                    weeklyChartCard
                    monthlyChartCard
                    timeOfDayCard
                    if !snapshot.subjectTotals.isEmpty {
                        subjectBarCard
                        subjectPieCard
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Analytics")
        .task(id: snapshotKey) {
            snapshot = AnalyticsSnapshot.build(from: sessions, heatmapRange: heatmapRange)
        }
    }

    private var pinnedHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let exportToast {
                exportToastBanner(exportToast)
            }
            exportSection
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Total Hours", StudyFormatting.duration(snapshot.overview.totalStudySeconds), "clock.fill")
            statCard("Total Sessions", "\(snapshot.overview.totalSessions)", "list.number")
            statCard("Avg Session", StudyFormatting.duration(snapshot.overview.averageSessionLength), "timer")
            statCard("Longest Session", StudyFormatting.duration(snapshot.overview.longestSessionSeconds), "arrow.up")
            statCard("Shortest Session", StudyFormatting.duration(snapshot.overview.shortestSessionSeconds), "arrow.down")
            statCard("Avg Daily Study", StudyFormatting.duration(snapshot.overview.averageDailyStudy), "calendar")
            statCard("Best Weekday", snapshot.overview.mostProductiveWeekday, "calendar.circle")
            statCard("Peak Hour", formatHour(snapshot.overview.mostProductiveHour), "clock.badge")
            statCard("YTD Total", StudyFormatting.duration(snapshot.overview.yearToDateSeconds), "chart.line.uptrend.xyaxis")
        }
    }

    private var scoresRow: some View {
        HStack(spacing: 12) {
            scoreCard("Consistency", snapshot.overview.consistencyScore, "flame.fill")
            scoreCard("Focus", snapshot.overview.focusScore, "scope")
            statCard("Current Streak", "\(snapshot.currentStreak) days", "flame")
            statCard("Longest Streak", "\(snapshot.longestStreak) days", "trophy.fill")
        }
    }

    private var comparisonRow: some View {
        HStack(spacing: 12) {
            statCard("7-Day Avg", StudyFormatting.duration(snapshot.overview.rolling7DayAverage), "7.circle")
            statCard("30-Day Avg", StudyFormatting.duration(snapshot.overview.rolling30DayAverage), "30.circle")
            if let week = snapshot.overview.previousWeekChangePercent {
                statCard("vs Last Week", formatPercent(week), week >= 0 ? "arrow.up.right" : "arrow.down.right")
            }
            if let month = snapshot.overview.previousMonthChangePercent {
                statCard("vs Last Month", formatPercent(month), month >= 0 ? "arrow.up.right" : "arrow.down.right")
            }
        }
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
            StudyHeatmapView(days: snapshot.dailyTotals, dayDetails: snapshot.heatmapDayDetails, range: heatmapRange)
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var dailyChartCard: some View {
        chartCard(title: "Daily Study Time (30 days)", selected: selectedDay.map { day in
            ChartHoverCard(
                title: day.formatted(date: .abbreviated, time: .omitted),
                value: StudyFormatting.duration(snapshot.dailyTrailing30.first { Calendar.current.isDate($0.date, inSameDayAs: day) }?.totalSeconds ?? 0),
                subtitle: nil
            )
        }) {
            Chart(snapshot.dailyTrailing30) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", day.totalSeconds / 60)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
            .chartXSelection(value: $selectedDay)
            .chartYAxisLabel("Minutes")
            .chartLegend(.hidden)
            .animation(nil, value: selectedDay)
            .frame(height: 180)
        }
    }

    private var weeklyChartCard: some View {
        chartCard(title: "Weekly Study Time", selected: selectedWeek.map { week in
            let minutes = snapshot.weeklyTotals.first { Calendar.current.isDate($0.weekStart, inSameDayAs: week) }?.totalSeconds ?? 0
            return ChartHoverCard(
                title: "Week of \(week.formatted(date: .abbreviated, time: .omitted))",
                value: StudyFormatting.duration(minutes),
                subtitle: nil
            )
        }) {
            Chart(snapshot.weeklyTotals) { week in
                BarMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", week.totalSeconds / 60)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
            .chartXSelection(value: $selectedWeek)
            .chartYAxisLabel("Minutes")
            .chartLegend(.hidden)
            .animation(nil, value: selectedWeek)
            .frame(height: 200)
        }
    }

    private var monthlyChartCard: some View {
        chartCard(title: "Monthly Study Time", selected: selectedMonth.map { month in
            let seconds = snapshot.monthlyTotals.first {
                Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month)
            }?.totalSeconds ?? 0
            return ChartHoverCard(
                title: month.formatted(.dateTime.month(.wide).year()),
                value: StudyFormatting.duration(seconds),
                subtitle: nil
            )
        }) {
            Chart(snapshot.monthlyTotals) { month in
                BarMark(
                    x: .value("Month", month.monthStart, unit: .month),
                    y: .value("Hours", month.totalSeconds / 3600)
                )
                .foregroundStyle(Color.purple.gradient)
            }
            .chartXSelection(value: $selectedMonth)
            .chartYAxisLabel("Hours")
            .chartLegend(.hidden)
            .animation(nil, value: selectedMonth)
            .frame(height: 200)
        }
    }

    private var timeOfDayCard: some View {
        chartCard(title: "Time of Day", selected: selectedHour.map { hour in
            let seconds = snapshot.hourTotals.first { $0.hour == hour }?.totalSeconds ?? 0
            return ChartHoverCard(
                title: formatHour(hour),
                value: StudyFormatting.duration(seconds),
                subtitle: "Total studied starting this hour"
            )
        }) {
            Chart(snapshot.hourTotals) { bucket in
                BarMark(
                    x: .value("Hour", bucket.hour),
                    y: .value("Minutes", bucket.totalSeconds / 60)
                )
                .foregroundStyle(Color.orange.gradient)
            }
            .chartXSelection(value: $selectedHour)
            .chartYAxisLabel("Minutes")
            .chartLegend(.hidden)
            .animation(nil, value: selectedHour)
            .frame(height: 180)
        }
    }

    private var subjectBarCard: some View {
        chartCard(title: "Time by Subject", selected: nil) {
            Chart(snapshot.subjectTotals.prefix(8)) { item in
                BarMark(
                    x: .value("Minutes", item.totalSeconds / 60),
                    y: .value("Subject", item.name)
                )
                .foregroundStyle(Color.mint.gradient)
            }
            .chartLegend(.hidden)
            .frame(height: min(280, CGFloat(snapshot.subjectTotals.prefix(8).count) * 32 + 40))
        }
    }

    private var subjectPieCard: some View {
        chartCard(title: "Subject Split", selected: nil) {
            Chart(snapshot.subjectTotals.prefix(6)) { item in
                SectorMark(
                    angle: .value("Minutes", item.totalSeconds / 60),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Subject", item.name))
            }
            .frame(height: 220)
        }
    }

    @ViewBuilder
    private func chartCard<Content: View>(title: String, selected: ChartHoverCard?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            if let selected { selected }
            content()
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        .drawingGroup()
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Export")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    exportButton("Heatmap PNG") { exportHeatmapPNG() }
                    exportButton("Sessions CSV") {
                        if let result = ExportService.exportSessionsCSV(sessions) { exportToast = result }
                    }
                    exportButton("Sessions JSON") {
                        if let result = ExportService.exportSessionsJSON(sessions) { exportToast = result }
                    }
                    exportButton("Sessions Markdown") {
                        if let result = ExportService.exportSessionsMarkdown(sessions) { exportToast = result }
                    }
                    exportButton("Monthly Report PDF") { exportMonthlyPDF() }
                }
            }
        }
    }

    private func exportButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .controlSize(.small)
    }

    private func statCard(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }

    private func scoreCard(_ title: String, _ score: Int, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(score)")
                .font(.title2.bold().monospacedDigit())
            ProgressView(value: Double(score), total: 100)
                .tint(score >= 70 ? .green : .accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h < 12 { return "\(h) AM" }
        if h == 12 { return "12 PM" }
        return "\(h - 12) PM"
    }

    private func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(Int(value.rounded()))%"
    }

    private func exportHeatmapPNG() {
        let exportView = VStack(alignment: .leading, spacing: 8) {
            Text("StudyBar Study Heatmap — \(heatmapRange.title)")
                .font(.headline)
            StudyHeatmapView(days: snapshot.dailyTotals, dayDetails: snapshot.heatmapDayDetails, range: heatmapRange, showLegend: true)
        }
        .padding(16)
        .background(Color.white)
        let width: CGFloat = heatmapRange == .weekly ? 360 : 900
        if let result = ExportService.savePNG(
            from: exportView,
            size: CGSize(width: width, height: 180),
            defaultName: "studybar-heatmap-\(heatmapRange.rawValue).png"
        ) {
            exportToast = result
        }
    }

    private func exportMonthlyPDF() {
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
        let report = MonthlyReportView(
            monthStart: monthStart,
            sessions: sessions,
            achievementsUnlocked: achievements
        )
        let name = "studybar-report-\(monthStart.formatted(.dateTime.year().month()))".replacingOccurrences(of: " ", with: "-")
        if let result = ExportService.savePDF(from: report, size: CGSize(width: 520, height: 720), defaultName: "\(name).pdf") {
            exportToast = result
        }
    }

    private func exportToastBanner(_ result: ExportResult) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Saved to Downloads")
                    .font(.subheadline.weight(.medium))
                Text(result.fileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Show in Finder") {
                ExportService.revealInFinder(result.url)
            }
            .controlSize(.small)
        }
        .padding(12)
        .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}
