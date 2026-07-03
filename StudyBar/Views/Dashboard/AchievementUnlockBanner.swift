import SwiftUI

struct AchievementUnlockBanner: View {
    @Bindable private var center = GamificationUnlockCenter.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let event = center.current {
            HStack(spacing: 12) {
                Image(systemName: event.icon)
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .symbolEffect(.bounce, value: event.id)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievement Unlocked")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                    Text(event.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                        center.dismissCurrent()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.yellow.opacity(0.35), lineWidth: 1))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            .onAppear {
                guard !reduceMotion else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    if center.current?.id == event.id {
                        center.dismissCurrent()
                    }
                }
            }
        }
    }
}
