import SwiftUI

// progress 0...1, drains from full to empty as a session runs down
struct ProgressRingView: View {
    var progress: Double
    var lineWidth: CGFloat = 2

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.2)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}
