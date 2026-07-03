import SwiftUI

struct StudyTheme: Hashable {
    let id: String
    let name: String
    let subtitle: String
    let accent: Color
    let ringPaused: Color
    let ringUrgent: Color
    let swatch: [Color]

    func ringColor(isPaused: Bool, isUrgent: Bool) -> Color {
        if isPaused { return ringPaused }
        if isUrgent { return ringUrgent }
        return accent
    }
}

enum StudyThemeId {
    static let classic = "classic"
    static let forest = "forest"
    static let sunset = "sunset"
    static let lavender = "lavender"
    static let ocean = "ocean"
    static let rose = "rose"
    static let monochrome = "monochrome"
}

enum StudyThemeCatalog {
    static let all: [StudyTheme] = [
        StudyTheme(
            id: StudyThemeId.classic,
            name: "Classic",
            subtitle: "System blue",
            accent: Color(red: 0.0, green: 0.48, blue: 1.0),
            ringPaused: .orange,
            ringUrgent: .red,
            swatch: [Color(red: 0.0, green: 0.48, blue: 1.0), .cyan, .white]
        ),
        StudyTheme(
            id: StudyThemeId.forest,
            name: "Forest",
            subtitle: "Calm greens",
            accent: Color(red: 0.18, green: 0.62, blue: 0.38),
            ringPaused: Color(red: 0.85, green: 0.65, blue: 0.2),
            ringUrgent: Color(red: 0.75, green: 0.28, blue: 0.22),
            swatch: [Color(red: 0.12, green: 0.42, blue: 0.28), Color(red: 0.18, green: 0.62, blue: 0.38), Color(red: 0.55, green: 0.78, blue: 0.45)]
        ),
        StudyTheme(
            id: StudyThemeId.sunset,
            name: "Sunset",
            subtitle: "Warm coral",
            accent: Color(red: 0.95, green: 0.42, blue: 0.28),
            ringPaused: Color(red: 0.95, green: 0.72, blue: 0.25),
            ringUrgent: Color(red: 0.82, green: 0.18, blue: 0.22),
            swatch: [Color(red: 0.95, green: 0.42, blue: 0.28), Color(red: 0.98, green: 0.62, blue: 0.35), Color(red: 0.55, green: 0.22, blue: 0.45)]
        ),
        StudyTheme(
            id: StudyThemeId.lavender,
            name: "Lavender",
            subtitle: "Soft purple",
            accent: Color(red: 0.55, green: 0.38, blue: 0.92),
            ringPaused: Color(red: 0.72, green: 0.55, blue: 0.95),
            ringUrgent: Color(red: 0.88, green: 0.32, blue: 0.55),
            swatch: [Color(red: 0.42, green: 0.28, blue: 0.72), Color(red: 0.55, green: 0.38, blue: 0.92), Color(red: 0.78, green: 0.68, blue: 0.98)]
        ),
        StudyTheme(
            id: StudyThemeId.ocean,
            name: "Ocean",
            subtitle: "Deep teal",
            accent: Color(red: 0.12, green: 0.62, blue: 0.72),
            ringPaused: Color(red: 0.35, green: 0.72, blue: 0.82),
            ringUrgent: Color(red: 0.92, green: 0.38, blue: 0.32),
            swatch: [Color(red: 0.05, green: 0.38, blue: 0.48), Color(red: 0.12, green: 0.62, blue: 0.72), Color(red: 0.45, green: 0.85, blue: 0.88)]
        ),
        StudyTheme(
            id: StudyThemeId.rose,
            name: "Rose",
            subtitle: "Pink accent",
            accent: Color(red: 0.88, green: 0.32, blue: 0.52),
            ringPaused: Color(red: 0.92, green: 0.58, blue: 0.68),
            ringUrgent: Color(red: 0.72, green: 0.15, blue: 0.28),
            swatch: [Color(red: 0.72, green: 0.22, blue: 0.42), Color(red: 0.88, green: 0.32, blue: 0.52), Color(red: 0.98, green: 0.75, blue: 0.82)]
        ),
        StudyTheme(
            id: StudyThemeId.monochrome,
            name: "Monochrome",
            subtitle: "Minimal slate",
            accent: Color(red: 0.42, green: 0.45, blue: 0.50),
            ringPaused: Color(red: 0.58, green: 0.60, blue: 0.64),
            ringUrgent: Color(red: 0.28, green: 0.28, blue: 0.30),
            swatch: [Color(red: 0.22, green: 0.24, blue: 0.26), Color(red: 0.42, green: 0.45, blue: 0.50), Color(red: 0.72, green: 0.74, blue: 0.76)]
        )
    ]

    static func theme(for id: String) -> StudyTheme {
        all.first { $0.id == id } ?? all[0]
    }

    static func applyTheme(id: String) {
        UserDefaults.standard.set(id, forKey: "selectedThemeId")
        NotificationCenter.default.post(name: .studyBarThemeChanged, object: id)
    }
}

enum MenuBarStyle: String, CaseIterable, Identifiable {
    case standard
    case compact
    case minimal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: "Standard"
        case .compact: "Compact"
        case .minimal: "Minimal"
        }
    }
}

private struct StudyThemeKey: EnvironmentKey {
    static let defaultValue = StudyThemeCatalog.all[0]
}

extension EnvironmentValues {
    var studyTheme: StudyTheme {
        get { self[StudyThemeKey.self] }
        set { self[StudyThemeKey.self] = newValue }
    }
}

struct StudyThemeProvider<Content: View>: View {
    @AppStorage("selectedThemeId") private var selectedThemeId = StudyThemeId.classic
    @ViewBuilder var content: () -> Content

    var body: some View {
        let theme = StudyThemeCatalog.theme(for: selectedThemeId)
        content()
            .environment(\.studyTheme, theme)
            .tint(theme.accent)
    }
}
