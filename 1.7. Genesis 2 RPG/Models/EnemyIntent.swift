import Foundation
import SwiftUI

enum EnemyIntentKind: String, Codable {
    case attack
    case defend
    case counter
    case counterStance
    case doubleStrikeFixed4
    case bleed
    case weak
    case stun
}

struct EnemyIntent: Codable, Hashable {
    var kind: EnemyIntentKind
    var value: Int = 0

    /// SF Symbol иконка (синхронизировано с карточками)
    var iconName: String {
        switch kind {
        case .attack: return "flame.fill"                      // Атака (как Мощный удар)
        case .defend: return "shield.fill"                     // Защита (как карта Защита)
        case .counter: return "arrow.counterclockwise.circle.fill" // Контратака (как карта Контратака)
        case .counterStance: return "arrow.counterclockwise.circle.fill" // Стойка (как карта Контратака)
        case .doubleStrikeFixed4: return "arrow.triangle.2.circlepath" // Двойной удар (как карта Двойной удар)
        case .bleed: return "drop.fill"
        case .weak: return "arrow.down.circle.fill"
        case .stun: return "bolt.circle.fill"
        }
    }
    
    /// Цвет иконки (синхронизировано с карточками)
    var iconColor: Color {
        switch kind {
        case .attack, .defend, .counter, .counterStance, .doubleStrikeFixed4, .bleed, .weak, .stun:
            return UIStyle.Colors.inkPrimary // Нейтральный цвет для базовых интентов
        }
    }

    @available(*, deprecated, message: "Используйте iconName вместо icon")
    var icon: String {
        switch kind {
        case .attack: return "🗡️"
        case .defend: return "🛡️"
        case .counter: return "🔁"
        case .counterStance: return "🔁"
        case .doubleStrikeFixed4: return "⚔️"
        case .bleed: return "🩸"
        case .weak: return "⬇️"
        case .stun: return "⚡️"
        }
    }

    /// RU label for UI.
    var titleRU: String {
        switch kind {
        case .attack: return "Атака"
        case .defend: return "Защита"
        case .counter: return "Контратака"
        case .counterStance: return "Стойка"
        case .doubleStrikeFixed4: return "Двойной удар"
        case .bleed: return "Кровоток"
        case .weak: return "Слабость"
        case .stun: return "Оглушение"
        }
    }

    /// Текст для отображения (без иконки, иконка отображается отдельно)
    var displayText: String {
        switch kind {
        case .attack:
            return "\(value)"
        case .defend:
            return "+\(value)"
        case .doubleStrikeFixed4:
            return "4×2"
        case .bleed, .weak, .stun:
            return "+\(value)"
        case .counter, .counterStance:
            return titleRU
        }
    }
    
    @available(*, deprecated, message: "Используйте displayText вместо displayRU")
    var displayRU: String {
        switch kind {
        case .attack:
            return "\(icon) \(value)"
        case .defend:
            return "\(icon) +\(value)"
        case .doubleStrikeFixed4:
            return "\(icon) 4×2"
        case .bleed, .weak, .stun:
            return "\(icon) +\(value)"
        case .counter, .counterStance:
            return "\(icon) \(titleRU)"
        }
    }

    var text: String {
        switch kind {
        case .attack: return "Атака"
        case .defend: return "Защита"
        case .counter: return "Контратака"
        case .counterStance: return "Стойка"
        case .doubleStrikeFixed4: return "Двойной удар"
        case .bleed: return "Кровоток"
        case .weak: return "Слабость"
        case .stun: return "Оглушение"
        }
    }
}
