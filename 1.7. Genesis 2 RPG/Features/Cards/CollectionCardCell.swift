import SwiftUI

struct CollectionCardCell: View {
    let card: ActionCardKind
    let isUnlocked: Bool
    let onTap: () -> Void
    
    // Фиксированный размер карты
    private let cardWidth: CGFloat = 160
    private let cardHeight: CGFloat = 200
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 8) {
                // Icon section - фиксированный размер
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isUnlocked ? UIStyle.Colors.mutedFill : Color.black.opacity(0.7))
                    
                    if isUnlocked {
                        Image(systemName: icon)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(iconColor)
                            .imageScale(.large)
                            .symbolRenderingMode(.hierarchical)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(UIStyle.Colors.textMuted)
                    }
                }
                .frame(width: 80, height: 80)  // Фиксированный размер иконки
                
                // Title - масштабируется
                Text(isUnlocked ? titleRU : "???")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UIStyle.Colors.textOnCard)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(height: 36)
                
                // Cost
                if isUnlocked {
                    Text("\(cost) ОД")
                        .font(.caption2)
                        .foregroundStyle(UIStyle.Colors.textMuted)
                }
            }
            .padding(10)
            .frame(width: cardWidth, height: cardHeight)  // Фиксированный размер карты
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isUnlocked ? UIStyle.Colors.cardFill : Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
            )
            .opacity(isUnlocked ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isUnlocked ? "\(titleRU), стоимость \(cost) очков действия" : "Заблокированная карта")
        .accessibilityHint("Нажмите для просмотра подробной информации")
    }
    
    private var titleRU: String {
        ActionCardTexts.title(for: card)
    }
    
    // MARK: - Icon System (синхронизировано с ActionCardView)
    
    private var icon: String {
        switch card {
        // Базовые карты
        case .powerStrike: return "flame.fill"                      // Мощный удар (пламя/урон)
        case .defend: return "shield.fill"                          // Щит
        case .doubleStrike: return "arrow.triangle.2.circlepath"   // Двойной удар
        case .counterStance: return "arrow.counterclockwise.circle.fill" // Контратака
        
        // Статусные карты (синхронизировано со статусами)
        case .bleedPlus2: return "drop.fill"                        // Кровоток (как статус)
        case .weakPlus1: return "arrow.down.circle.fill"            // Слабость (как статус)
        case .stun1: return "bolt.fill"                            // Оглушение (как статус)
        
        // Синергийные карты (минималистичные, без многоточия)
        case .bleedStrike: return "drop.fill"                       // Кровавый удар (капля крови, красная)
        case .weakDefend: return "shield.fill"                     // Ослабляющий щит (щит, оранжевый)
        
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "questionmark.circle.fill"
        }
    }
    
    /// Цвет иконки карточки (синхронизировано со статусами)
    private var iconColor: Color {
        switch card {
        // Статусные карты используют цвета статусов
        case .bleedPlus2, .bleedStrike: return Color.red
        case .weakPlus1, .weakDefend: return Color.orange
        case .stun1: return Color.purple
        
        // Базовые карты - нейтральный цвет
        default: return UIStyle.Colors.textOnCard
        }
    }
    
    private var cost: Int {
        switch card {
        case .powerStrike: return 1
        case .defend: return 1
        case .doubleStrike: return 2
        case .counterStance: return 2
        case .bleedPlus2: return 1
        case .weakPlus1: return 1
        case .stun1: return 2
        case .bleedStrike: return 2
        case .weakDefend: return 2
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return 0
        }
    }
}
