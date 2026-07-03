import SwiftUI

struct PlanetView: View {
    let subjectName: String
    let hours: Double
    let tier: PlanetTier

    private var color: Color { TimelineEngine.subjectColor(for: subjectName) }

    var body: some View {
        ZStack {
            if tier.rawValue >= PlanetTier.nebula.rawValue {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.35), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
            }

            if tier.rawValue >= PlanetTier.constellation.rawValue {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(.white.opacity(0.7))
                        .frame(width: 3, height: 3)
                        .offset(x: cos(Double(i) * .pi / 3) * 70, y: sin(Double(i) * .pi / 3) * 50)
                }
            }

            if tier.rawValue >= PlanetTier.rings.rawValue {
                Ellipse()
                    .stroke(color.opacity(0.55), lineWidth: 2)
                    .frame(width: planetSize * 1.6, height: planetSize * 0.45)
                    .rotationEffect(.degrees(-18))
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.95), color.opacity(0.55)],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 2,
                        endRadius: planetSize * 0.6
                    )
                )
                .frame(width: planetSize, height: planetSize)
                .shadow(color: color.opacity(0.35), radius: 12)

            if tier.rawValue >= PlanetTier.moons.rawValue {
                Circle()
                    .fill(.secondary.opacity(0.7))
                    .frame(width: planetSize * 0.22, height: planetSize * 0.22)
                    .offset(x: planetSize * 0.55, y: -planetSize * 0.2)
            }

            if tier.rawValue >= PlanetTier.stars.rawValue {
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .offset(x: CGFloat(30 + i * 12), y: CGFloat(-20 + i * 8))
                }
            }
        }
        .frame(width: 180, height: 140)
    }

    private var planetSize: CGFloat {
        switch tier {
        case .seedling: 36
        case .grown: 48
        case .rings: 54
        case .moons: 60
        case .stars: 66
        case .nebula: 72
        case .constellation: 78
        }
    }
}
