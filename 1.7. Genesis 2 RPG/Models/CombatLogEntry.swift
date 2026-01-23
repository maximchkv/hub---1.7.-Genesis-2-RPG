import Foundation

struct CombatLogEntry: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case normal
        case system
        case separator
    }

    var id: UUID = UUID()
    var text: String
    var isPlayer: Bool
    var kind: Kind = .normal

    init(id: UUID = UUID(), text: String, isPlayer: Bool, kind: Kind = .normal) {
        self.id = id
        self.text = text
        self.isPlayer = isPlayer
        self.kind = kind
    }

    static func system(_ text: String) -> CombatLogEntry {
        CombatLogEntry(text: text, isPlayer: false, kind: .system)
    }

    static func separator() -> CombatLogEntry {
        CombatLogEntry(text: "", isPlayer: false, kind: .separator)
    }
}
