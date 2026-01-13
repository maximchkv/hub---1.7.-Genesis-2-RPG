import Foundation

enum EnemyIntentKind: String, Codable {
    case attack
    case defend
    case counter
    case counterStance
    case doubleStrikeFixed4
}

struct EnemyIntent: Codable, Hashable {
    var kind: EnemyIntentKind
    var value: Int = 0

    var icon: String {
        switch kind {
        case .attack: return "🗡️"
        case .defend: return "🛡️"
        case .counter: return "🔁"
        case .counterStance: return "🔁"
        case .doubleStrikeFixed4: return "⚔️"
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
        }
    }

    /// Compact RU description for the current intent, used in UI.
    var displayRU: String {
        switch kind {
        case .attack:
            return "\(icon) \(value)"
        case .defend:
            return "\(icon) +\(value)"
        case .doubleStrikeFixed4:
            return "\(icon) 4×2"
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
        }
    }
}
