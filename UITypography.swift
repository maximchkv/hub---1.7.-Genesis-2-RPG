import SwiftUI

// VS1.0 — Global Design System: Typography
// Централизованная типографика (готова к замене на кастомный шрифт)

enum UITypography {

    static func title() -> Font {
        .system(size: 32, weight: .bold, design: .serif)
    }

    static func subtitle() -> Font {
        .system(size: 16, weight: .medium, design: .serif)
    }

    static func body() -> Font {
        .system(size: 14, weight: .regular)
    }

    static func caption() -> Font {
        .system(size: 12, weight: .regular)
    }
}
