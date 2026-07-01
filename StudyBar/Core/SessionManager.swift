import Foundation
import Observation
import SwiftData
import AppKit

enum SessionPhase: Equatable {
    case idle
    case running
    case paused
}

struct SessionCompletionEvent: Equatable {
    let subjectName: String
    let minutes: Int
    let token: UUID
}

@Observable
final class SessionManager {
    private(set) var phase: SessionPhase = .idle
    private(set) var subjectName: String = ""
    private(set) var topicName: String?
    private(set) var plannedDuration: TimeInterval = 0
    private(set) var remaining: TimeInterval = 0
    private(set) var startedAt: Date?
    private(set) var lastCompletion: SessionCompletionEvent?
    private(set) var autoPausedBySystem = false

    var draftNotes: String = ""
    var pendingOpenHistory = false

    private let modelContext: ModelContext
    private var timer: Timer?
    private var completionClearTask: Task<Void, Never>?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var progress: Double {
        guard plannedDuration > 0 else { return 0 }
        return remaining / plannedDuration
    }

    var isUrgent: Bool {
        phase != .idle && remaining > 0 && remaining <= 5 * 60
    }

    var remainingText: String {
        let total = max(0, Int(remaining.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    func start(subjectName: String, topicName: String?, minutes: Int) {
        self.subjectName = subjectName
        self.topicName = topicName
        plannedDuration = TimeInterval(minutes * 60)
        remaining = plannedDuration
        startedAt = Date()
        phase = .running
        autoPausedBySystem = false
        lastCompletion = nil

        NotificationManager.shared.fireSessionStarted(subjectName: subjectName, topicName: topicName, minutes: minutes)
        startTimer()
    }

    func startLastSession() {
        guard phase == .idle else { return }
        var descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let last = try? modelContext.fetch(descriptor).first else { return }
        let minutes = max(1, Int(last.plannedDuration / 60))
        start(subjectName: last.subjectName, topicName: last.topicName, minutes: minutes)
    }

    func pause() {
        guard phase == .running else { return }
        autoPausedBySystem = false
        phase = .paused
        stopTimer()
    }

    func pauseBySystem() {
        guard phase == .running else { return }
        autoPausedBySystem = true
        phase = .paused
        stopTimer()
    }

    func resume() {
        guard phase == .paused else { return }
        autoPausedBySystem = false
        phase = .running
        startTimer()
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
        guard phase == .running || phase == .paused else { return }
        let seconds = TimeInterval(minutes * 60)
        plannedDuration += seconds
        remaining += seconds
    }

    func requestOpenHistory() {
        pendingOpenHistory = true
        NSApp.activate(ignoringOtherApps: true)
    }

    func consumePendingOpenHistory() -> Bool {
        guard pendingOpenHistory else { return false }
        pendingOpenHistory = false
        return true
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
        let session = StudySession(
            subjectName: subjectName,
            topicName: topicName,
            plannedDuration: plannedDuration,
            actualDuration: plannedDuration - remaining,
            startedAt: startedAt,
            endedAt: Date(),
            completed: completed,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        modelContext.insert(session)
        draftNotes = ""
    }

    private func resetToIdle() {
        phase = .idle
        subjectName = ""
        topicName = nil
        plannedDuration = 0
        remaining = 0
        startedAt = nil
        autoPausedBySystem = false
    }
}
