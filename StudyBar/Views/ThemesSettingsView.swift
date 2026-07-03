import SwiftUI

struct ThemesSettingsView: View {
    @AppStorage("selectedThemeId") private var selectedThemeId = StudyThemeId.classic
    @AppStorage("menuBarStyle") private var menuBarStyleRaw = MenuBarStyle.standard.rawValue
    @AppStorage("timerTypographyRounded") private var timerTypographyRounded = false
    @AppStorage("floatingTimerThemedBorder") private var floatingTimerThemedBorder = true

    private var menuBarStyle: MenuBarStyle {
        MenuBarStyle(rawValue: menuBarStyleRaw) ?? .standard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick an accent palette for rings, charts, and highlights.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(StudyThemeCatalog.all, id: \.id) { theme in
                    themeCard(theme)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Appearance")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Picker("Menu bar style", selection: $menuBarStyleRaw) {
                    ForEach(MenuBarStyle.allCases) { style in
                        Text(style.title).tag(style.rawValue)
                    }
                }
                .pickerStyle(.segmented)
        .onChange(of: menuBarStyleRaw) { _, _ in
            NotificationCenter.default.post(name: .studyBarThemeChanged, object: nil)
        }
        .onChange(of: timerTypographyRounded) { _, _ in
            NotificationCenter.default.post(name: .studyBarThemeChanged, object: nil)
        }

                Toggle("Rounded timer digits", isOn: $timerTypographyRounded)
                Toggle("Themed floating timer border", isOn: $floatingTimerThemedBorder)
                    .onChange(of: floatingTimerThemedBorder) { _, _ in
                        NotificationCenter.default.post(name: .studyBarThemeChanged, object: nil)
                    }

                Text(menuBarStyleHint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(compact ? 0 : 24)
        .navigationTitle(compact ? "" : "Themes")
    }

    var compact: Bool = false

    private var menuBarStyleHint: String {
        switch menuBarStyle {
        case .standard: "Full icon + countdown in the menu bar."
        case .compact: "Tighter spacing and smaller timer text."
        case .minimal: "Timer text only when a session is active."
        }
    }

    private func themeCard(_ theme: StudyTheme) -> some View {
        let selected = selectedThemeId == theme.id
        return Button {
            selectedThemeId = theme.id
            StudyThemeCatalog.applyTheme(id: theme.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(theme.swatch.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.swatch[index])
                            .frame(height: 20)
                    }
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.name)
                            .font(.subheadline.weight(.semibold))
                        Text(theme.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.accent)
                    }
                }
                ZStack {
                    Circle()
                        .stroke(theme.accent.opacity(0.2), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 36, height: 36)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? theme.accent.opacity(0.1) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? theme.accent.opacity(0.5) : Color.primary.opacity(0.1), lineWidth: selected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
