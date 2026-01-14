import Foundation

struct CollectionState: Codable, Equatable {
    var unlockedCards: Set<ActionCardKind> = []
    var cardStats: [ActionCardKind: CardStats] = [:]
    
    // Check if a card is unlocked
    func isUnlocked(_ kind: ActionCardKind) -> Bool {
        return unlockedCards.contains(kind)
    }
    
    // Unlock a card
    mutating func unlock(_ kind: ActionCardKind) {
        unlockedCards.insert(kind)
        if cardStats[kind] == nil {
            cardStats[kind] = CardStats()
        }
    }
    
    // Update stats for a card
    mutating func incrementUsage(for kind: ActionCardKind) {
        if cardStats[kind] == nil {
            cardStats[kind] = CardStats()
        }
        cardStats[kind]?.incrementUsage()
    }
    
    // Get stats for a card
    func stats(for kind: ActionCardKind) -> CardStats {
        return cardStats[kind] ?? CardStats()
    }
    
    // Get all cards in the game (sorted: unlocked first, then locked)
    var allCards: [ActionCardKind] {
        let all = ActionCardKind.allCases.filter { !$0.isPlaceholder } + ActionCardKind.allCases.filter { $0.isPlaceholder }
        return all.sorted { first, second in
            let firstUnlocked = isUnlocked(first)
            let secondUnlocked = isUnlocked(second)
            
            // Unlocked cards first
            if firstUnlocked != secondUnlocked {
                return firstUnlocked
            }
            
            // Within same unlock status, sort by raw value
            return first.rawValue < second.rawValue
        }
    }
    
    // Progress tracking
    var unlockedCount: Int {
        return unlockedCards.count
    }
    
    var totalCount: Int {
        return ActionCardKind.allCases.count
    }
}
