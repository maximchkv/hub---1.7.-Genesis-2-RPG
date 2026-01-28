import Foundation

enum ActionCardTag: String, Codable, Hashable, CaseIterable {
    case attacking
    case defending
    case debuff
    case controlling
    case support
    case weapon
}

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

    /// Теги, описывающие функциональную роль карты
    var tags: [ActionCardTag] {
        switch self {
        case .powerStrike:
            return [.attacking, .weapon]
        case .defend:
            return [.defending]
        case .doubleStrike:
            return [.attacking, .weapon]
        case .counterStance:
            return [.attacking, .defending, .weapon]
        case .bleedPlus2:
            return [.debuff]
        case .weakPlus1:
            return [.debuff]
        case .stun1:
            return [.debuff, .controlling]
        case .bleedStrike:
            return [.attacking, .debuff, .weapon]
        case .weakDefend:
            return [.defending, .debuff]
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return []
        }
    }

    /// Условный \"tier\" карты для вражеских паттернов (1 — базовые, 2+ — более сложные/сильные)
    var enemyTier: Int {
        switch self {
        case .powerStrike, .defend, .bleedPlus2, .weakPlus1:
            return 1
        case .doubleStrike, .counterStance, .stun1, .bleedStrike, .weakDefend:
            return 2
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return 0
        }
    }

    /// Удобный фильтр: все виды карт, содержащие заданный набор тегов
    static func all(with requiredTags: Set<ActionCardTag>) -> [ActionCardKind] {
        guard !requiredTags.isEmpty else { return Array(Self.allCases) }
        return Self.allCases.filter { kind in
            let cardTags = Set(kind.tags)
            return requiredTags.isSubset(of: cardTags)
        }
    }
}

struct ActionCard: Identifiable, Codable {
    let id: UUID
    let kind: ActionCardKind
    var level: Int
    var cardClass: String

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

    init(kind: ActionCardKind, level: Int = 1, cardClass: String = "initial") {
        self.id = UUID()
        self.kind = kind
        self.level = level
        self.cardClass = cardClass
    }
}
