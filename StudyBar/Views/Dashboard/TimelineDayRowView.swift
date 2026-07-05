import SwiftUI
import SwiftData

struct TimelineDayRowView: View {
    let day: TimelineDayRow
    let zoom: TimelineZoom
    let isFirst: Bool
    let isLast: Bool
    @Binding var hoveredSessionId: PersistentIdentifier?
    @Binding var hoverAnchorRect: CGRect?

    private var calendar: Calendar { .current }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            gitRail
            VStack(alignment: .leading, spacing: 6) {
                header
                timelineTrack
            }
        }
    }

    private var gitRail: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.secondary.opacity(isFirst ? 0 : 0.25))
                .frame(width: 2, height: 10)
            Circle()
                .fill(day.totalDuration > 0 ? Color.accentColor : Color.secondary.opacity(0.35))
                .frame(width: 10, height: 10)
            Rectangle()
                .fill(Color.secondary.opacity(isLast ? 0 : 0.25))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 14)
    }

    private var header: some View {
        HStack {
            Text(dayLabel)
                .font(.subheadline.weight(.semibold))
            if day.totalDuration > 0 {
                Text(StudyFormatting.duration(day.totalDuration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(day.sessions.count) session\(day.sessions.count == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var dayLabel: String {
        if calendar.isDateInToday(day.date) { return "Today" }
        if calendar.isDateInYesterday(day.date) { return "Yesterday" }
        return day.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private var timelineTrack: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.04))
                hourGrid(width: width)
                ForEach(day.sessions) { item in
                    sessionBlocks(item, width: width)
                }
            }
        }
        .frame(height: zoom.rowHeight)
    }

    private func hourGrid(width: CGFloat) -> some View {
        let window = zoom.window(on: day.date, calendar: calendar)
        let span = window.end - window.start
        let hours = Int(window.end / 3600) - Int(window.start / 3600)
        return ZStack(alignment: .leading) {
            ForEach(0...hours, id: \.self) { offset in
                let hour = Int(window.start / 3600) + offset
                let x = CGFloat((Double(hour) * 3600 - window.start) / span) * width
                if x >= 0 && x <= width {
                    Rectangle()
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 1)
                        .offset(x: x)
                    if hour % zoom.hourLabelInterval == 0 && zoom != .compact {
                        Text(hourLabel(hour))
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                            .offset(x: max(0, x + 2), y: -zoom.rowHeight / 2 + 8)
                    }
                }
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12a" }
        if h < 12 { return "\(h)a" }
        if h == 12 { return "12p" }
        return "\(h - 12)p"
    }

    @ViewBuilder
    private func sessionBlocks(_ item: TimelineSessionItem, width: CGFloat) -> some View {
        let color = TimelineEngine.subjectColor(for: item.session.subjectName)
        ForEach(item.activeBlocks) { block in
            let blockWidth = max(4, (block.xEnd - block.xStart) * width)
            let blockHeight = zoom.rowHeight - 10
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .overlay {
                        ForEach(item.pauses) { pause in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                                .frame(width: max(2, (pause.xEnd - pause.xStart) * width), height: zoom.rowHeight - 14)
                                .offset(x: pause.xStart * width - block.xStart * width, y: 2)
                        }
                    }
                    .onHover { hovering in
                        if hovering {
                            hoveredSessionId = item.id
                            hoverAnchorRect = geo.frame(in: .named("timelineHoverSpace"))
                        } else if hoveredSessionId == item.id {
                            hoveredSessionId = nil
                            hoverAnchorRect = nil
                        }
                    }
            }
            .frame(width: blockWidth, height: blockHeight)
            .offset(x: block.xStart * width, y: 5)
        }
    }
}
