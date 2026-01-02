import Foundation

enum EnemyIntentKind: String, Codable {
    case attack
    case defend
    case counter
}

struct EnemyIntent: Codable, Hashable {
    var kind: EnemyIntentKind

    var icon: String {
        switch kind {
        case .attack: return "🗡️"
        case .defend: return "🛡️"
        case .counter: return "🔁"
        }
    }

    var text: String {
        switch kind {
        case .attack: return "Attack"
        case .defend: return "Defend"
        case .counter: return "Counter"
        }
    }
}
