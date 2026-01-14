import Foundation

enum RoomKind: String, Codable {
    case combat
    case chest
    case elite
    case rest
    case event
    case boss
}

struct RoomOption: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: RoomKind
    var isLocked: Bool
    
    // Preview fields
    let difficulty: Int // 0 = none, 1 = easy, 2 = medium, 3 = hard
    let descriptionText: String
    let previewEnemy: RuntimeEnemyKind?

    var title: String {
        switch kind {
        case .combat: return "Битва"
        case .chest: return "Сундук"
        case .elite: return "Элита"
        case .rest: return "Отдых"
        case .event: return "Событие"
        case .boss: return "Босс"
        }
    }

    var icon: String {
        switch kind {
        case .combat: return "⚔️"
        case .chest: return "🧰"
        case .elite: return "💀"
        case .rest: return "🔥"
        case .event: return "❓"
        case .boss: return "👑"
        }
    }

    var kindDescription: String {
        switch kind {
        case .combat: return "Враг на пути"
        case .elite: return "Элитный враг"
        case .boss: return "Финал акта"
        case .chest: return "Награда"
        case .rest: return "Восстановление"
        case .event: return "Выбор"
        }
    }

    var subtitle: String {
        if kind == .chest && isLocked {
            return "Заблокировано: нельзя пропускать 3 боя подряд"
        }
        return ""
    }

    init(
        kind: RoomKind,
        isLocked: Bool = false,
        difficulty: Int = 0,
        descriptionText: String = "",
        previewEnemy: RuntimeEnemyKind? = nil
    ) {
        self.id = UUID()
        self.kind = kind
        self.isLocked = isLocked
        self.difficulty = difficulty
        self.descriptionText = descriptionText
        self.previewEnemy = previewEnemy
    }
}
