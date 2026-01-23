import Foundation

struct Artifact: Identifiable, Codable, Hashable {
    let id: UUID
    let icon: String
    let name: String
    let description: String
    let incomeBonus: Int

    init(icon: String, name: String, description: String, incomeBonus: Int) {
        self.id = UUID()
        self.icon = icon
        self.name = name
        self.description = description
        self.incomeBonus = incomeBonus
    }
}
