import Foundation

struct CombatLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String

    init(_ text: String) {
        self.id = UUID()
        self.text = text
    }
}
