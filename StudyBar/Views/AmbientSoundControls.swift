import SwiftUI

struct AmbientSoundControls: View {
    var compact: Bool
    @Bindable private var engine = AmbientSoundEngine.shared
    @AppStorage("ambientSoundVolume") private var ambientSoundVolume = 0.35
    @AppStorage("ambientSoundAutoPlay") private var ambientSoundAutoPlay = true
    @Environment(SessionManager.self) private var sessionManager

    private let gridColumns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 10) {
            if !compact {
                Text("Ambient Sound")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            soundGrid

            if engine.activeSound != .off {
                HStack(spacing: 6) {
                    Image(systemName: engine.isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Slider(value: $ambientSoundVolume, in: 0.05...0.8, step: 0.05)
                        .onChange(of: ambientSoundVolume) { _, v in
                            engine.setVolume(v)
                        }
                }
                if !compact {
                    Toggle("Auto-play during sessions", isOn: $ambientSoundAutoPlay)
                        .font(.caption)
                }
            }
        }
        .onAppear {
            engine.applyUserDefaults()
            engine.setVolume(ambientSoundVolume)
        }
    }

    private var soundGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: compact ? 4 : 6) {
            ForEach(AmbientSound.allCases) { sound in
                Button {
                    engine.select(sound, playIfSessionActive: sessionManager.phase == .running)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: sound.systemImage)
                            .font(.system(size: compact ? 10 : 12))
                            .frame(width: 14)
                        Text(sound.title)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, compact ? 4 : 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(engine.activeSound == sound ? Color.accentColor : .secondary)
                    .background(
                        engine.activeSound == sound ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 7)
                    )
                }
                .buttonStyle(.plain)
                .help(sound.title)
            }
        }
    }
}
