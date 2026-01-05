import SwiftUI

// VS1.0 — Global Design System: UIStyle
// Один источник правды для фона, цветов и радиусов.

enum UIStyle {

    // MARK: - Background
    // Единый вызов для всех экранов:
    // UIStyle.background().ignoresSafeArea()
    static func background() -> some View {
        Image("bg_parchment")
            .resizable()
            .scaledToFill()
    }

    // Back-compat (если где-то уже используется)
    // UIStyle.backgroundImage().ignoresSafeArea()
    static func backgroundImage() -> some View {
        background()
    }

    // Опционально: если хочешь иногда подменять ассет
    static func backgroundImage(named name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
    }

    // MARK: - Colors
    enum Color {
        static let parchment = SwiftUI.Color(red: 0.96, green: 0.94, blue: 0.90)
        static let inkPrimary = SwiftUI.Color(red: 0.20, green: 0.18, blue: 0.15)
        static let inkSecondary = SwiftUI.Color(red: 0.45, green: 0.42, blue: 0.38)

        static let cardFill = SwiftUI.Color.white.opacity(0.65)
        static let cardStroke = SwiftUI.Color.black.opacity(0.08)

        static let accent = SwiftUI.Color(red: 0.55, green: 0.45, blue: 0.30)
    }

    // MARK: - Radius
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 14
}
