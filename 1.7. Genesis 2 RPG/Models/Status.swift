import Foundation
import SwiftUI

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
    
    // MARK: - Status Icons System
    
    /// Иконка для статуса (SF Symbols)
    var iconName: String {
        switch self {
        case .bleed: return "drop.fill"           // Капелька крови
        case .weak: return "arrow.down.circle.fill" // Слабость (стрелка вниз)
        case .vulnerable: return "exclamationmark.triangle.fill" // Уязвимость (предупреждение)
        case .stun: return "bolt.fill"            // Оглушение (молния)
        }
    }
    
    /// Цвет иконки статуса
    var iconColor: Color {
        switch self {
        case .bleed: return Color.red              // Красный для кровотечения
        case .weak: return Color.orange            // Оранжевый для слабости
        case .vulnerable: return Color.yellow      // Желтый для уязвимости
        case .stun: return Color.purple            // Фиолетовый для оглушения
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
