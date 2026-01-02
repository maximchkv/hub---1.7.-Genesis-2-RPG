import Foundation

struct RewardState: Identifiable, Codable, Hashable {
    let id: UUID
    let options: [ActionCardKind]   // 3 уникальных вида карт

    init(options: [ActionCardKind]) {
        self.id = UUID()
        self.options = options
    }
}
