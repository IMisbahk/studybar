import AVFoundation
import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case off
    case whiteNoise
    case pinkNoise
    case rain
    case thunder
    case ocean
    case cafe
    case fan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: "Off"
        case .whiteNoise: "White"
        case .pinkNoise: "Pink"
        case .rain: "Rain"
        case .thunder: "Storm"
        case .ocean: "Ocean"
        case .cafe: "Café"
        case .fan: "Fan"
        }
    }

    var systemImage: String {
        switch self {
        case .off: "speaker.slash"
        case .whiteNoise: "waveform"
        case .pinkNoise: "waveform.path"
        case .rain: "cloud.rain"
        case .thunder: "cloud.bolt.rain"
        case .ocean: "water.waves"
        case .cafe: "cup.and.saucer"
        case .fan: "wind"
        }
    }
}

@MainActor
@Observable
final class AmbientSoundEngine {
    static let shared = AmbientSoundEngine()

    private(set) var isPlaying = false
    private(set) var activeSound: AmbientSound = .off

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private let noiseState = NoiseState()
    private let audioParams = AudioParams()
    private var observers: [NSObjectProtocol] = []

    private init() {}

    func startObservingSession() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: .studyBarSessionPhaseChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.syncWithSession() }
        })
    }

    func applyUserDefaults() {
        let raw = UserDefaults.standard.string(forKey: "ambientSoundId") ?? AmbientSound.off.rawValue
        if raw == "fireplace" {
            activeSound = .off
            UserDefaults.standard.set(AmbientSound.off.rawValue, forKey: "ambientSoundId")
        } else {
            activeSound = AmbientSound(rawValue: raw) ?? .off
        }
        audioParams.gain = Float(UserDefaults.standard.object(forKey: "ambientSoundVolume") as? Double ?? 0.35)
        audioParams.kind = activeSound
    }

    func setVolume(_ value: Double) {
        audioParams.gain = Float(value.clamped(to: 0...1))
        UserDefaults.standard.set(value, forKey: "ambientSoundVolume")
    }

    func select(_ sound: AmbientSound, playIfSessionActive: Bool = true) {
        activeSound = sound
        UserDefaults.standard.set(sound.rawValue, forKey: "ambientSoundId")
        audioParams.kind = sound
        if sound == .off {
            stop()
            return
        }
        if playIfSessionActive {
            syncWithSession(forcePlay: true)
        } else if isPlaying {
            restartEngine()
        }
    }

    private func syncWithSession(forcePlay: Bool = false) {
        let autoPlay = UserDefaults.standard.object(forKey: "ambientSoundAutoPlay") as? Bool ?? true
        guard let sessionManager = SessionManager.current else { return }

        switch sessionManager.phase {
        case .idle:
            stop()
        case .paused:
            pauseEngine()
        case .running:
            guard autoPlay || forcePlay, activeSound != .off else { return }
            if engine != nil, !isPlaying {
                resumeEngine()
            } else if !isPlaying {
                play(activeSound)
            }
        }
    }

    private func play(_ sound: AmbientSound) {
        guard sound != .off else { stop(); return }
        audioParams.kind = sound
        activeSound = sound
        restartEngine()
    }

    func stop() {
        engine?.stop()
        if let sourceNode, let engine {
            engine.detach(sourceNode)
        }
        engine = nil
        sourceNode = nil
        isPlaying = false
        noiseState.reset()
    }

    private func pauseEngine() {
        engine?.pause()
        isPlaying = false
    }

    private func resumeEngine() {
        try? engine?.start()
        isPlaying = true
    }

    private func restartEngine() {
        stop()
        let engine = AVAudioEngine()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let state = noiseState
        let params = audioParams
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let kind = params.kind
            let volume = params.gain
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let frames = Int(frameCount)

            for frame in 0..<frames {
                let sample: Float
                switch kind {
                case .off:
                    sample = 0
                case .whiteNoise:
                    sample = Float.random(in: -1...1) * volume
                case .pinkNoise:
                    sample = state.pinkSample() * volume
                case .rain:
                    sample = state.rainSample() * volume
                case .thunder:
                    sample = state.thunderSample() * volume
                case .ocean:
                    sample = state.oceanSample() * volume
                case .cafe:
                    sample = state.cafeSample() * volume
                case .fan:
                    sample = state.fanSample() * volume
                }
                for buffer in abl {
                    guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                    data[frame] = sample
                }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
            self.engine = engine
            self.sourceNode = node
            isPlaying = true
        } catch {
            self.engine = nil
            self.sourceNode = nil
            isPlaying = false
        }
    }
}

private final class AudioParams {
    var kind: AmbientSound = .off
    var gain: Float = 0.35
}

private final class NoiseState {
    private var rainLP: Float = 0
    private var brown: Float = 0
    private var cafeTick: Int = 0
    private var pinkB0: Float = 0
    private var pinkB1: Float = 0
    private var pinkB2: Float = 0
    private var pinkB3: Float = 0
    private var pinkB4: Float = 0
    private var pinkB5: Float = 0
    private var pinkB6: Float = 0
    private var fanLP: Float = 0
    private var oceanPhase: Float = 0
    private var oceanBrown: Float = 0
    private var thunderTick: Int = 0
    private var nextThunderIn: Int = 400_000
    private var rumble: Float = 0
    private var rumbleEnv: Float = 0

    func reset() {
        rainLP = 0
        brown = 0
        cafeTick = 0
        pinkB0 = 0; pinkB1 = 0; pinkB2 = 0; pinkB3 = 0
        pinkB4 = 0; pinkB5 = 0; pinkB6 = 0
        fanLP = 0
        oceanPhase = 0
        oceanBrown = 0
        thunderTick = 0
        nextThunderIn = 400_000
        rumble = 0
        rumbleEnv = 0
    }

    func pinkSample() -> Float {
        let white = Float.random(in: -1...1)
        pinkB0 = 0.99886 * pinkB0 + white * 0.0555179
        pinkB1 = 0.99332 * pinkB1 + white * 0.0750759
        pinkB2 = 0.96900 * pinkB2 + white * 0.1538520
        pinkB3 = 0.86650 * pinkB3 + white * 0.3104856
        pinkB4 = 0.55000 * pinkB4 + white * 0.5329522
        pinkB5 = -0.7616 * pinkB5 - white * 0.0168980
        let out = pinkB0 + pinkB1 + pinkB2 + pinkB3 + pinkB4 + pinkB5 + pinkB6 + white * 0.5362
        pinkB6 = white * 0.115926
        return out * 0.11
    }

    func rainSample() -> Float {
        let white = Float.random(in: -1...1)
        rainLP = rainLP * 0.992 + white * 0.008
        return rainLP * 1.4
    }

    func thunderSample() -> Float {
        thunderTick += 1
        let rain = rainSample() * 0.85
        if thunderTick >= nextThunderIn {
            rumbleEnv = 1
            thunderTick = 0
            nextThunderIn = Int.random(in: 350_000...650_000)
        }
        if rumbleEnv > 0.001 {
            let white = Float.random(in: -1...1)
            rumble = rumble * 0.998 + white * 0.002
            rumbleEnv *= 0.99985
            return rain + rumble * rumbleEnv * 2.5
        }
        return rain
    }

    func oceanSample() -> Float {
        let white = Float.random(in: -1...1)
        oceanBrown = (oceanBrown + white * 0.012) * 0.997
        oceanPhase += 0.00008
        let swell = (sin(oceanPhase * .pi * 2) + 1) * 0.5
        let swell2 = (sin(oceanPhase * .pi * 2 * 0.7 + 1.2) + 1) * 0.5
        let mod = 0.35 + swell * 0.35 + swell2 * 0.2
        return oceanBrown * mod * 1.3
    }

    func cafeSample() -> Float {
        let white = Float.random(in: -1...1)
        brown = (brown + white * 0.015) * 0.996
        cafeTick += 1
        var out = brown * 0.9
        if cafeTick % 22050 == 0 {
            out += Float.random(in: 0.02...0.06)
        }
        return out
    }

    func fanSample() -> Float {
        let white = Float.random(in: -1...1)
        fanLP = fanLP * 0.985 + white * 0.015
        return fanLP * 1.1
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
