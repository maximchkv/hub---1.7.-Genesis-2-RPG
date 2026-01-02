import Foundation

enum ActionCardKind: String, Codable {
    case powerStrike      // Мощный удар
    case defend           // Защита (важно: кейс называется defend, не guard)
    case doubleStrike     // Двойной удар
    case counterStance    // Контратака
}

struct ActionCard: Identifiable, Codable {
    let id: UUID
    let kind: ActionCardKind

    var cost: Int {
        switch kind {
        case .powerStrike: return 1
        case .defend: return 1
        case .doubleStrike: return 2
        case .counterStance: return 2
        }
    }

    init(kind: ActionCardKind) {
        self.id = UUID()
        self.kind = kind
    }
}
