import Foundation

enum StatusType: String, Codable, CaseIterable, Hashable {
    case bleed
    case weak
    case vulnerable
    case stun

    var displayNameRU: String {
        switch self {
        case .bleed: return "Кровоток"
        case .weak: return "Слабость"
        case .vulnerable: return "Уязвимость"
        case .stun: return "Оглушение"
        }
    }
}

struct StatusInstance: Identifiable, Codable, Hashable {
    let id: UUID
    var type: StatusType
    var stacks: Int

    init(type: StatusType, stacks: Int) {
        self.id = UUID()
        self.type = type
        self.stacks = stacks
    }
}

enum BattleSide: Codable, Hashable {
    case player
    case enemy
}

struct TurnStartOutcome {
    var didSkipTurn: Bool
    var logLines: [String]

    init(didSkipTurn: Bool = false, logLines: [String] = []) {
        self.didSkipTurn = didSkipTurn
        self.logLines = logLines
    }
}
