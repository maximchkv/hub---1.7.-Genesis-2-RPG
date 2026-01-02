import Foundation

enum ActionCardKind: String, Codable {
    case strongAttack
    case doubleAttack
    case defend
    case counter
}

struct ActionCard: Identifiable, Codable {
    let id: UUID
    let kind: ActionCardKind
    let cost: Int

    init(kind: ActionCardKind, cost: Int) {
        self.id = UUID()
        self.kind = kind
        self.cost = cost
    }
}
