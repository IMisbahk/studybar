import Foundation
import Observation
import SwiftData
import AppKit

enum SessionPhase: Equatable {
    case idle
    case running
    case paused
}

enum SessionTimerMode: Equatable {
    case countdown
    case stopwatch
}

enum PopoverTab: String, CaseIterable, Hashable {
    case timer
    case history
    case settings

    var title: String {
        switch self {
        case .timer: "Timer"
        case .history: "Timeline"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .timer: "timer"
        case .history: "timeline.selection"
        case .settings: "gearshape"
        }
    }
}

struct SessionCompletionEvent: Equatable {
    let subjectName: String
    let minutes: Int
    let token: UUID
}

@Observable
final class SessionManager {
    private(set) var phase: SessionPhase = .idle
    private(set) var timerMode: SessionTimerMode = .countdown
    private(set) var subjectName: String = ""
    private(set) var topicName: String?
    private(set) var plannedDuration: TimeInterval = 0
    private(set) var remaining: TimeInterval = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var startedAt: Date?
    private(set) var lastCompletion: SessionCompletionEvent?
    private(set) var autoPausedBySystem = false

    var draftNotes: String = ""
    var selectedTab: PopoverTab = .timer

    private let modelContext: ModelContext
    private var timer: Timer?
    private var completionClearTask: Task<Void, Never>?
    private var segmentDrafts: [SegmentDraft] = []

    private struct SegmentDraft {
        var kind: SessionSegmentKind
        var startedAt: Date
        var endedAt: Date?
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var isStopwatch: Bool { timerMode == .stopwatch }

    var progress: Double {
        guard timerMode == .countdown, plannedDuration > 0 else { return 1 }
        return remaining / plannedDuration
    }

    var isUrgent: Bool {
        timerMode == .countdown && phase != .idle && remaining > 0 && remaining <= 5 * 60
    }

    var menuBarTimeText: String {
        isStopwatch ? elapsedText : remainingText
    }

    var remainingText: String {
        formatClock(max(0, Int(remaining.rounded())))
    }

    var elapsedText: String {
        formatClock(max(0, Int(elapsed.rounded())), allowHours: true)
    }

    func start(subjectName: String, topicName: String?, minutes: Int) {
        timerMode = .countdown
        self.subjectName = subjectName
        self.topicName = topicName
        plannedDuration = TimeInterval(minutes * 60)
        remaining = plannedDuration
        elapsed = 0
        startedAt = Date()
        phase = .running
        autoPausedBySystem = false
        lastCompletion = nil
        resetSegmentDrafts()
        beginSegment(.active)

        NotificationManager.shared.fireSessionStarted(subjectName: subjectName, topicName: topicName, minutes: minutes)
        startTimer()
        notifyPhaseChanged()
    }

    func startStopwatch(subjectName: String, topicName: String?) {
        timerMode = .stopwatch
        self.subjectName = subjectName
        self.topicName = topicName
        plannedDuration = 0
        remaining = 0
        elapsed = 0
        startedAt = Date()
        phase = .running
        autoPausedBySystem = false
        lastCompletion = nil
        resetSegmentDrafts()
        beginSegment(.active)

        NotificationManager.shared.fireStopwatchStarted(subjectName: subjectName, topicName: topicName)
        startTimer()
        notifyPhaseChanged()
    }

    func startLastSession() {
        guard phase == .idle else { return }
        var descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let last = try? modelContext.fetch(descriptor).first else { return }
        if last.openEnded {
            startStopwatch(subjectName: last.subjectName, topicName: last.topicName)
        } else {
            let minutes = max(1, Int(last.plannedDuration / 60))
            start(subjectName: last.subjectName, topicName: last.topicName, minutes: minutes)
        }
    }

    func pause() {
        guard phase == .running else { return }
        autoPausedBySystem = false
        endCurrentSegment()
        beginSegment(.pause)
        phase = .paused
        stopTimer()
        notifyPhaseChanged()
    }

    func pauseBySystem() {
        guard phase == .running else { return }
        autoPausedBySystem = true
        endCurrentSegment()
        beginSegment(.systemPause)
        phase = .paused
        stopTimer()
        notifyPhaseChanged()
    }

    func resume() {
        guard phase == .paused else { return }
        autoPausedBySystem = false
        endCurrentSegment()
        beginSegment(.active)
        phase = .running
        startTimer()
        notifyPhaseChanged()
    }

    func resumeIfAutoPaused() {
        guard phase == .paused, autoPausedBySystem else { return }
        resume()
    }

    func stop() {
        guard phase != .idle else { return }
        logSession(completed: false)
        stopTimer()
        resetToIdle()
    }

    func extend(byMinutes minutes: Int) {
        guard timerMode == .countdown, phase == .running || phase == .paused else { return }
        let seconds = TimeInterval(minutes * 60)
        plannedDuration += seconds
        remaining += seconds
    }

    func requestOpenHistory() {
        selectedTab = .history
    }

    private func notifyPhaseChanged() {
        NotificationCenter.default.post(name: .studyBarSessionPhaseChanged, object: nil)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        if timerMode == .stopwatch {
            elapsed += 1
            return
        }
        remaining = max(0, remaining - 1)
        if remaining <= 0 {
            complete()
        }
    }

    private func complete() {
        let minutes = Int(plannedDuration / 60)
        NotificationManager.shared.fireSessionCompleted(subjectName: subjectName, minutes: minutes)
        if UserDefaults.standard.bool(forKey: "soundOnSessionEnd") {
            NSSound(named: "Glass")?.play()
        }
        logSession(completed: true)
        emitCompletion(subjectName: subjectName, minutes: minutes)
        stopTimer()
        resetToIdle()
    }

    private func emitCompletion(subjectName: String, minutes: Int) {
        completionClearTask?.cancel()
        lastCompletion = SessionCompletionEvent(subjectName: subjectName, minutes: minutes, token: UUID())
        completionClearTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            lastCompletion = nil
        }
    }

    private func logSession(completed: Bool) {
        guard let startedAt else { return }
        let trimmedNotes = draftNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let actual = isStopwatch ? elapsed : (plannedDuration - remaining)
        endCurrentSegment()
        let endedAt = Date()
        let session = StudySession(
            subjectName: subjectName,
            topicName: topicName,
            plannedDuration: plannedDuration,
            actualDuration: actual,
            startedAt: startedAt,
            endedAt: endedAt,
            completed: completed,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            openEnded: isStopwatch
        )
        modelContext.insert(session)
        attachSegments(to: session, fallbackEnd: endedAt)
        draftNotes = ""
        segmentDrafts = []
    }

    private func resetSegmentDrafts() {
        segmentDrafts = []
    }

    private func beginSegment(_ kind: SessionSegmentKind) {
        segmentDrafts.append(SegmentDraft(kind: kind, startedAt: Date(), endedAt: nil))
    }

    private func endCurrentSegment() {
        guard !segmentDrafts.isEmpty else { return }
        segmentDrafts[segmentDrafts.count - 1].endedAt = Date()
    }

    private func attachSegments(to session: StudySession, fallbackEnd: Date) {
        let drafts = segmentDrafts.isEmpty
            ? [SegmentDraft(kind: .active, startedAt: session.startedAt, endedAt: fallbackEnd)]
            : segmentDrafts
        for draft in drafts {
            let end = draft.endedAt ?? fallbackEnd
            guard end > draft.startedAt else { continue }
            let segment = SessionSegment(kind: draft.kind, startedAt: draft.startedAt, endedAt: end)
            segment.session = session
            session.segments.append(segment)
            modelContext.insert(segment)
        }
    }

    private func resetToIdle() {
        phase = .idle
        timerMode = .countdown
        subjectName = ""
        topicName = nil
        plannedDuration = 0
        remaining = 0
        elapsed = 0
        startedAt = nil
        autoPausedBySystem = false
        segmentDrafts = []
        notifyPhaseChanged()
    }

    private func formatClock(_ totalSeconds: Int, allowHours: Bool = false) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if allowHours && hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
