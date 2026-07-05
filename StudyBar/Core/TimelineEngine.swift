import Foundation
import SwiftData
import SwiftUI

enum TimelineZoom: String, CaseIterable, Identifiable {
    case day
    case focus
    case compact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "Day"
        case .focus: "Focus"
        case .compact: "Compact"
        }
    }

    // seconds from midnight for visible window
    func window(on day: Date, calendar: Calendar = .current) -> (start: TimeInterval, end: TimeInterval) {
        (0, 24 * 3600)
    }

    var rowHeight: CGFloat {
        switch self {
        case .day: 64
        case .focus: 56
        case .compact: 36
        }
    }

    var hourLabelInterval: Int {
        switch self {
        case .day: 2
        case .focus: 3
        case .compact: 6
        }
    }
}

enum TimelineDateRange: String, CaseIterable, Identifiable {
    case all
    case last7
    case last30
    case last90

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All time"
        case .last7: "Last 7 days"
        case .last30: "Last 30 days"
        case .last90: "Last 90 days"
        }
    }

    func startDate(calendar: Calendar = .current, now: Date = Date()) -> Date? {
        let today = calendar.startOfDay(for: now)
        switch self {
        case .all: return nil
        case .last7: return calendar.date(byAdding: .day, value: -6, to: today)
        case .last30: return calendar.date(byAdding: .day, value: -29, to: today)
        case .last90: return calendar.date(byAdding: .day, value: -89, to: today)
        }
    }
}

struct TimelineActiveBlock: Identifiable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    let xStart: CGFloat
    let xEnd: CGFloat
}

struct TimelinePauseInfo: Identifiable, Hashable {
    let id: UUID
    let kind: SessionSegmentKind
    let startedAt: Date
    let endedAt: Date
    let resumeAt: Date
    let xStart: CGFloat
    let xEnd: CGFloat
}

struct TimelineSessionItem: Identifiable, Hashable {
    let session: StudySession
    let activeBlocks: [TimelineActiveBlock]
    let pauses: [TimelinePauseInfo]
    let gapsAfter: [TimelineGap]

    var id: PersistentIdentifier { session.persistentModelID }
}

struct TimelineGap: Identifiable, Hashable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let duration: TimeInterval
}

struct TimelineDayRow: Identifiable, Hashable {
    let date: Date
    let sessions: [TimelineSessionItem]
    let totalDuration: TimeInterval

    var id: Date { date }
}

enum TimelineEngine {
    static func subjectColor(for name: String) -> Color {
        let hash = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.62, brightness: 0.88)
    }

    static func allSubjectNames(from sessions: [StudySession]) -> [String] {
        Array(Set(sessions.map(\.subjectName))).sorted()
    }

    static func filter(
        sessions: [StudySession],
        searchText: String,
        subjects: Set<String>,
        dateRange: TimelineDateRange,
        completedOnly: Bool,
        calendar: Calendar = .current
    ) -> [StudySession] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let rangeStart = dateRange.startDate(calendar: calendar)

        return sessions.filter { session in
            if completedOnly, !session.completed { return false }
            if let rangeStart, session.startedAt < rangeStart { return false }
            if !subjects.isEmpty, !subjects.contains(session.subjectName) { return false }
            guard !query.isEmpty else { return true }
            return session.subjectName.lowercased().contains(query)
                || (session.topicName?.lowercased().contains(query) ?? false)
                || (session.notes?.lowercased().contains(query) ?? false)
        }
    }

    static func buildDays(
        from sessions: [StudySession],
        zoom: TimelineZoom,
        calendar: Calendar = .current
    ) -> [TimelineDayRow] {
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.startedAt) }
        return grouped.map { day, daySessions in
            let sorted = daySessions.sorted { $0.startedAt < $1.startedAt }
            let items = sorted.enumerated().map { index, session in
                buildSessionItem(session, on: day, zoom: zoom, calendar: calendar, nextSession: sorted[safe: index + 1])
            }
            let total = sorted.reduce(0) { $0 + $1.actualDuration }
            return TimelineDayRow(date: day, sessions: items, totalDuration: total)
        }
        .sorted { $0.date > $1.date }
    }

    private static func buildSessionItem(
        _ session: StudySession,
        on day: Date,
        zoom: TimelineZoom,
        calendar: Calendar,
        nextSession: StudySession?
    ) -> TimelineSessionItem {
        let window = zoom.window(on: day, calendar: calendar)
        let segments = session.segments.sorted { $0.startedAt < $1.startedAt }

        let activeBlocks: [TimelineActiveBlock]
        let pauses: [TimelinePauseInfo]

        if segments.isEmpty {
            activeBlocks = [makeBlock(
                id: UUID(),
                start: session.startedAt,
                end: session.endedAt,
                day: day,
                window: window,
                calendar: calendar
            )].compactMap { $0 }
            pauses = []
        } else {
            var blocks: [TimelineActiveBlock] = []
            var pauseList: [TimelinePauseInfo] = []
            for segment in segments {
                switch segment.kind {
                case .active:
                    if let block = makeBlock(
                        id: UUID(),
                        start: segment.startedAt,
                        end: segment.endedAt,
                        day: day,
                        window: window,
                        calendar: calendar
                    ) {
                        blocks.append(block)
                    }
                case .pause, .systemPause:
                    if let pause = makePause(
                        segment: segment,
                        day: day,
                        window: window,
                        calendar: calendar
                    ) {
                        pauseList.append(pause)
                    }
                }
            }
            activeBlocks = blocks
            pauses = pauseList
        }

        var gaps: [TimelineGap] = []
        if let next = nextSession {
            let gap = next.startedAt.timeIntervalSince(session.endedAt)
            if gap >= 60 {
                gaps.append(TimelineGap(
                    id: UUID(),
                    startedAt: session.endedAt,
                    endedAt: next.startedAt,
                    duration: gap
                ))
            }
        }

        return TimelineSessionItem(
            session: session,
            activeBlocks: activeBlocks,
            pauses: pauses,
            gapsAfter: gaps
        )
    }

    private static func makeBlock(
        id: UUID,
        start: Date,
        end: Date,
        day: Date,
        window: (start: TimeInterval, end: TimeInterval),
        calendar: Calendar
    ) -> TimelineActiveBlock? {
        guard let (xStart, xEnd) = xRange(for: start, end: end, on: day, window: window, calendar: calendar) else {
            return nil
        }
        return TimelineActiveBlock(id: id, start: start, end: end, xStart: xStart, xEnd: xEnd)
    }

    private static func makePause(
        segment: SessionSegment,
        day: Date,
        window: (start: TimeInterval, end: TimeInterval),
        calendar: Calendar
    ) -> TimelinePauseInfo? {
        guard let (xStart, xEnd) = xRange(
            for: segment.startedAt,
            end: segment.endedAt,
            on: day,
            window: window,
            calendar: calendar
        ) else { return nil }
        return TimelinePauseInfo(
            id: UUID(),
            kind: segment.kind,
            startedAt: segment.startedAt,
            endedAt: segment.endedAt,
            resumeAt: segment.endedAt,
            xStart: xStart,
            xEnd: xEnd
        )
    }

    private static func xRange(
        for start: Date,
        end: Date,
        on day: Date,
        window: (start: TimeInterval, end: TimeInterval),
        calendar: Calendar
    ) -> (CGFloat, CGFloat)? {
        let dayStart = calendar.startOfDay(for: day)
        let startSec = start.timeIntervalSince(dayStart)
        let endSec = end.timeIntervalSince(dayStart)
        let visibleStart = max(startSec, window.start)
        let visibleEnd = min(endSec, window.end)
        guard visibleEnd > visibleStart else { return nil }
        let span = window.end - window.start
        let xStart = CGFloat((visibleStart - window.start) / span)
        let xEnd = CGFloat((visibleEnd - window.start) / span)
        return (xStart, xEnd)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
