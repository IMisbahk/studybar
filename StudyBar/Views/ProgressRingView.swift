import SwiftUI

// progress 0...1, drains from full to empty as a session runs down
struct ProgressRingView: View {
    var progress: Double
    var lineWidth: CGFloat = 2
    var isPaused: Bool = false
    var isUrgent: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var pulse = false

    private var clampedProgress: Double {
        max(0, min(1, progress))
    }

    private var ringColor: Color {
        if isPaused { return .orange }
        if isUrgent { return .red }
        return .accentColor
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(ringColor.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(ringAnimation, value: clampedProgress)
                .scaleEffect(pulseScale)
        }
        .opacity(breatheOpacity)
        .onAppear { updateMotion() }
        .onChange(of: isPaused) { _, _ in updateMotion() }
        .onChange(of: isUrgent) { _, _ in updateMotion() }
        .onChange(of: reduceMotion) { _, _ in updateMotion() }
    }

    private var ringAnimation: Animation {
        reduceMotion ? .linear(duration: 1) : .spring(response: 0.45, dampingFraction: 0.85)
    }

    private var breatheOpacity: Double {
        guard isPaused, !reduceMotion, breathe else { return 1 }
        return 0.55
    }

    private var pulseScale: CGFloat {
        guard isUrgent, !reduceMotion, pulse else { return 1 }
        return 1.06
    }

    private func updateMotion() {
        breathe = false
        pulse = false
        guard !reduceMotion else { return }

        if isPaused {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        if isUrgent {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
