struct PlayerMeta: Codable {
    var days: Int = 0
    var gold: Int = 0
    var bestFloor: Int = 0
    var artifacts: [Artifact] = []
    var collection: CollectionState = CollectionState()

    // MVP: базовый доход + бонусы от артефактов
    var incomePerDay: Int {
        let bonus = artifacts.reduce(0) { $0 + $1.incomeBonus }
        return 3 + bonus
    }
    
    // Collection helpers
    mutating func unlockCard(_ kind: ActionCardKind) {
        collection.unlock(kind)
    }
    
    mutating func incrementCardUsage(_ kind: ActionCardKind) {
        collection.incrementUsage(for: kind)
    }
}
