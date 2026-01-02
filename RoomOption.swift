import Foundation

enum RoomKind: String, Codable {
    case combat
    case chest
}

struct RoomOption: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: RoomKind
    var isLocked: Bool

    var title: String {
        switch kind {
        case .combat: return "Battle"
        case .chest: return "Chest"
        }
    }

    var icon: String {
        switch kind {
        case .combat: return "⚔️"
        case .chest: return "🧰"
        }
    }

    var subtitle: String {
        if kind == .chest && isLocked {
            return "Locked: can't take 3 chests in a row"
        }
        return ""
    }

    init(kind: RoomKind, isLocked: Bool = false) {
        self.id = UUID()
        self.kind = kind
        self.isLocked = isLocked
    }
}
