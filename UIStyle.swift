import SwiftUI

// MARK: - Global Visual Language (VL-01A)

enum UIStyle {

    // MARK: Colors (light parchment base)
    static let background = Color(red: 0.97, green: 0.95, blue: 0.92)
    static let panelBackground = Color.white.opacity(0.9)
    static let border = Color.black.opacity(0.12)
    static let textPrimary = Color.black
    static let textSecondary = Color.black.opacity(0.6)

    // MARK: Radii
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16

    // MARK: Spacing
    static let paddingXS: CGFloat = 4
    static let paddingS: CGFloat = 8
    static let paddingM: CGFloat = 12
    static let paddingL: CGFloat = 16

    // MARK: Animation
    static let spring = Animation.spring(
        response: 0.25,
        dampingFraction: 0.85
    )
}
