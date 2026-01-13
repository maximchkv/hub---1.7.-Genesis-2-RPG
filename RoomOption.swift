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

    var title: String {
        switch kind {
        case .combat: return "Battle"
        case .chest: return "Chest"
        case .elite: return "Elite"
        case .rest: return "Rest"
        case .event: return "Event"
        case .boss: return "Boss"
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
        case .combat: return "Combat • Random enemy"
        case .elite: return "Elite • Hard fight"
        case .boss: return "Boss • Act climax"
        case .chest: return "Chest • Relic"
        case .rest: return "Rest • Pause"
        case .event: return "Event • Choice"
        }
    }

    var subtitle: String {
        if kind == .chest && isLocked {
            return "Locked: can't take 3 non-combat rooms in a row"
        }
        return ""
    }

    init(kind: RoomKind, isLocked: Bool = false) {
        self.id = UUID()
        self.kind = kind
        self.isLocked = isLocked
    }
}
