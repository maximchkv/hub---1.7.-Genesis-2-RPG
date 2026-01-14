import SwiftUI

// VS1.0 — Global Design System: UIStyle
// Один источник правды для фона, цветов, радиусов, отступов и базовых стилей.

enum UIStyle {

    // MARK: - Background
    // Использование:
    // UIStyle.background().ignoresSafeArea()
    static func background() -> some View {
        Image("bg_parchment")
            .resizable()
            .scaledToFill()
    }

    // MARK: - Palette
    // Важно: НЕ называем это "Color", чтобы не конфликтовать с SwiftUI.Color
    enum Colors {
        static let parchment   = SwiftUI.Color(red: 0.96, green: 0.94, blue: 0.90)
        static let inkPrimary  = SwiftUI.Color(red: 0.20, green: 0.18, blue: 0.15)
        static let inkSecondary = SwiftUI.Color(red: 0.45, green: 0.42, blue: 0.38)

        static let cardFill    = SwiftUI.Color.white.opacity(0.65)
        static let cardStroke  = SwiftUI.Color.black.opacity(0.08)

        static let accent      = SwiftUI.Color(red: 0.55, green: 0.45, blue: 0.30)
        static let mutedFill   = SwiftUI.Color.black.opacity(0.06)

        // Consistent HP green (used across UI)
        static let hpGreen     = SwiftUI.Color(red: 0.12, green: 0.45, blue: 0.20)
    }

    // MARK: - Radius
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 14

    // MARK: - Spacing (базовые отступы)
    enum Spacing {
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
    }

    // MARK: - Card wrapper
    // Использование:
    // VStack { ... }.uiCard()
    struct CardModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                        .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                )
        }
    }

    // MARK: - Primary button style
    // Использование:
    // Button("...") { ... }.buttonStyle(UIStyle.PrimaryButtonStyle())
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: UIStyle.buttonRadius)
                        .fill(UIStyle.Colors.accent)
                        .opacity(configuration.isPressed ? 0.85 : 1.0)
                )
        }
    }

    // MARK: - Card button style
    // Использование:
    // Button { ... } label: { ... }.buttonStyle(UIStyle.CardButtonStyle())
    //
    // Предполагается, что label уже оформлен как карточка (например через `.uiCard()`).
    struct CardButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
                .opacity(configuration.isPressed ? 0.96 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                        .stroke(UIStyle.Colors.accent.opacity(configuration.isPressed ? 0.28 : 0.0), lineWidth: 1)
                )
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

// MARK: - View helpers
extension View {
    func uiCard() -> some View {
        self.modifier(UIStyle.CardModifier())
    }
    
    // ⚠️ УДАЛЕНЫ хелперы uiSafeAreaScreenPadding и uiMaxReadableWidth.
    // Они не работали надёжно и привели к 7 итерациям багфикса RewardView.
    // Используй простой .padding() на контенте — см. UI_DESIGN_RULES.md
}
