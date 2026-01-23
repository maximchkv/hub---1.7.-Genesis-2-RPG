import Foundation

enum ActionCardKind: String, Codable, Hashable, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    // Базовые карты (разблокированы с начала)
    case powerStrike      // Мощный удар
    case defend           // Защита (важно: кейс называется defend, не guard)
    case doubleStrike     // Двойной удар
    case counterStance    // Контратака

    // 031B: Status cards
    case bleedPlus2       // Кровоток
    case weakPlus1        // Ослабить
    case stun1            // Оглушить
    
    // Синергийные карты
    case bleedStrike      // Кровавый удар
    case weakDefend       // Ослабляющий щит
    
    // Placeholder карты (будущий контент)
    case placeholder1
    case placeholder2
    case placeholder3
    case placeholder4
    case placeholder5
    
    var isBaseCard: Bool {
        switch self {
        case .powerStrike, .defend, .doubleStrike, .counterStance, .bleedPlus2, .weakPlus1, .stun1, .bleedStrike, .weakDefend:
            return true
        default:
            return false
        }
    }
    
    var isPlaceholder: Bool {
        switch self {
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return true
        default:
            return false
        }
    }
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
        case .bleedPlus2: return 1
        case .weakPlus1: return 1
        case .stun1: return 2
        case .bleedStrike: return 2
        case .weakDefend: return 2
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return 0
        }
    }

    init(kind: ActionCardKind) {
        self.id = UUID()
        self.kind = kind
    }
}
