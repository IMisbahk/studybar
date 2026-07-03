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

    private var overview: AnalyticsOverview { AnalyticsEngine.overview(from: sessions) }
    private var dailyTotals: [DayStudyTotal] { AnalyticsEngine.dailyTotals(from: sessions, range: heatmapRange) }
    private var heatmapDayDetails: [Date: DayStudyDetail] { AnalyticsEngine.dayDetails(from: sessions, range: heatmapRange) }
    private var weeklyTotals: [WeekStudyTotal] { AnalyticsEngine.weeklyTotals(from: sessions, trailingWeeks: 12) }
    private var monthlyTotals: [MonthStudyTotal] { AnalyticsEngine.monthlyTotals(from: sessions, trailingMonths: 12) }
    private var dailyTrailing30: [DayStudyTotal] { AnalyticsEngine.dailyTotalsTrailing(days: 30, from: sessions) }
    private var hourTotals: [HourStudyTotal] { AnalyticsEngine.hourOfDayTotals(from: sessions) }
    private var subjectTotals: [SubjectStudyTotal] { AnalyticsEngine.subjectTotals(from: sessions) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                overviewGrid
                scoresRow
                comparisonRow
                heatmapCard
                dailyChartCard
                weeklyChartCard
                monthlyChartCard
                timeOfDayCard
                if !subjectTotals.isEmpty {
                    subjectBarCard
                    subjectPieCard
                }
                exportSection
                if let exportToast {
                    exportToastBanner(exportToast)
                }
            }
            .padding(24)
        }
        .navigationTitle("Analytics")
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Total Hours", StudyFormatting.duration(overview.totalStudySeconds), "clock.fill")
            statCard("Total Sessions", "\(overview.totalSessions)", "list.number")
            statCard("Avg Session", StudyFormatting.duration(overview.averageSessionLength), "timer")
            statCard("Longest Session", StudyFormatting.duration(overview.longestSessionSeconds), "arrow.up")
            statCard("Shortest Session", StudyFormatting.duration(overview.shortestSessionSeconds), "arrow.down")
            statCard("Avg Daily Study", StudyFormatting.duration(overview.averageDailyStudy), "calendar")
            statCard("Best Weekday", overview.mostProductiveWeekday, "calendar.circle")
            statCard("Peak Hour", formatHour(overview.mostProductiveHour), "clock.badge")
            statCard("YTD Total", StudyFormatting.duration(overview.yearToDateSeconds), "chart.line.uptrend.xyaxis")
        }
    }

    private var scoresRow: some View {
        HStack(spacing: 12) {
            scoreCard("Consistency", overview.consistencyScore, "flame.fill")
            scoreCard("Focus", overview.focusScore, "scope")
            statCard("Current Streak", "\(AnalyticsEngine.currentStreak(from: sessions)) days", "flame")
            statCard("Longest Streak", "\(AnalyticsEngine.longestStreak(from: sessions)) days", "trophy.fill")
        }
    }

    private var comparisonRow: some View {
        HStack(spacing: 12) {
            statCard("7-Day Avg", StudyFormatting.duration(overview.rolling7DayAverage), "7.circle")
            statCard("30-Day Avg", StudyFormatting.duration(overview.rolling30DayAverage), "30.circle")
            if let week = overview.previousWeekChangePercent {
                statCard("vs Last Week", formatPercent(week), week >= 0 ? "arrow.up.right" : "arrow.down.right")
            }
            if let month = overview.previousMonthChangePercent {
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
            StudyHeatmapView(days: dailyTotals, dayDetails: heatmapDayDetails, range: heatmapRange)
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var dailyChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Study Time (30 days)")
                .font(.headline)
            if let selectedDay {
                ChartHoverCard(
                    title: selectedDay.formatted(date: .abbreviated, time: .omitted),
                    value: StudyFormatting.duration(dailyTrailing30.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }?.totalSeconds ?? 0),
                    subtitle: nil
                )
            }
            Chart(dailyTrailing30) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", day.totalSeconds / 60)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
            .chartXSelection(value: $selectedDay)
            .chartYAxisLabel("Minutes")
            .frame(height: 180)
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Study Time")
                .font(.headline)
            if let selectedWeek {
                let minutes = weeklyTotals.first { Calendar.current.isDate($0.weekStart, inSameDayAs: selectedWeek) }?.totalSeconds ?? 0
                ChartHoverCard(
                    title: "Week of \(selectedWeek.formatted(date: .abbreviated, time: .omitted))",
                    value: StudyFormatting.duration(minutes),
                    subtitle: nil
                )
            }
            Chart(weeklyTotals) { week in
                BarMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", week.totalSeconds / 60)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
            .chartXSelection(value: $selectedWeek)
            .chartYAxisLabel("Minutes")
            .frame(height: 200)
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var monthlyChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monthly Study Time")
                .font(.headline)
            if let selectedMonth {
                let seconds = monthlyTotals.first {
                    Calendar.current.isDate($0.monthStart, equalTo: selectedMonth, toGranularity: .month)
                }?.totalSeconds ?? 0
                ChartHoverCard(
                    title: selectedMonth.formatted(.dateTime.month(.wide).year()),
                    value: StudyFormatting.duration(seconds),
                    subtitle: nil
                )
            }
            Chart(monthlyTotals) { month in
                BarMark(
                    x: .value("Month", month.monthStart, unit: .month),
                    y: .value("Hours", month.totalSeconds / 3600)
                )
                .foregroundStyle(Color.purple.gradient)
            }
            .chartXSelection(value: $selectedMonth)
            .chartYAxisLabel("Hours")
            .frame(height: 200)
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var timeOfDayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time of Day")
                .font(.headline)
            if let selectedHour {
                let seconds = hourTotals.first { $0.hour == selectedHour }?.totalSeconds ?? 0
                ChartHoverCard(title: formatHour(selectedHour), value: StudyFormatting.duration(seconds), subtitle: "Total studied starting this hour")
            }
            Chart(hourTotals) { bucket in
                BarMark(
                    x: .value("Hour", bucket.hour),
                    y: .value("Minutes", bucket.totalSeconds / 60)
                )
                .foregroundStyle(Color.orange.gradient)
            }
            .chartXSelection(value: $selectedHour)
            .chartYAxisLabel("Minutes")
            .frame(height: 180)
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var subjectBarCard: some View {
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

    private var subjectPieCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subject Split")
                .font(.headline)
            Chart(subjectTotals.prefix(6)) { item in
                SectorMark(
                    angle: .value("Minutes", item.totalSeconds / 60),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Subject", item.name))
            }
            .frame(height: 220)
        }
        .padding(14)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Export")
                .font(.headline)
            FlowLayout(spacing: 8) {
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
                exportButton("Monthly Report PDF") {
                    exportMonthlyPDF()
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
            StudyHeatmapView(days: dailyTotals, dayDetails: heatmapDayDetails, range: heatmapRange, showLegend: true)
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

// simple flow layout for export buttons
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
