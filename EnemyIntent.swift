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

    var text: String {
        switch kind {
        case .attack: return "Attack"
        case .defend: return "Defend"
        case .counter: return "Counter"
        case .counterStance: return "Counter Stance"
        case .doubleStrikeFixed4: return "Double Strike"
        }
    }
}
