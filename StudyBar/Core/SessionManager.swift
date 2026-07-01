import Foundation
import Observation
import SwiftData
import AppKit

enum SessionPhase: Equatable {
    case idle
    case running
    case paused
}

@Observable
final class SessionManager {
    private(set) var phase: SessionPhase = .idle
    private(set) var subjectName: String = ""
    private(set) var topicName: String?
    private(set) var plannedDuration: TimeInterval = 0
    private(set) var remaining: TimeInterval = 0
    private(set) var startedAt: Date?

    private let modelContext: ModelContext
    private var timer: Timer?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var progress: Double {
        guard plannedDuration > 0 else { return 0 }
        return remaining / plannedDuration
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

        NotificationManager.shared.fireSessionStarted(subjectName: subjectName, topicName: topicName, minutes: minutes)
        startTimer()
    }

    func pause() {
        guard phase == .running else { return }
        phase = .paused
        stopTimer()
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .running
        startTimer()
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
        NotificationManager.shared.fireSessionCompleted(subjectName: subjectName, minutes: Int(plannedDuration / 60))
        if UserDefaults.standard.bool(forKey: "soundOnSessionEnd") {
            NSSound(named: "Glass")?.play()
        }
        logSession(completed: true)
        stopTimer()
        resetToIdle()
    }

    private func logSession(completed: Bool) {
        guard let startedAt else { return }
        let session = StudySession(
            subjectName: subjectName,
            topicName: topicName,
            plannedDuration: plannedDuration,
            actualDuration: plannedDuration - remaining,
            startedAt: startedAt,
            endedAt: Date(),
            completed: completed
        )
        modelContext.insert(session)
    }

    private func resetToIdle() {
        phase = .idle
        subjectName = ""
        topicName = nil
        plannedDuration = 0
        remaining = 0
        startedAt = nil
    }
}
