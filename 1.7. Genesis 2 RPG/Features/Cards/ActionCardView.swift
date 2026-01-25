import SwiftUI

enum CardPlayabilityState {
    case available          // Можно играть
    case insufficientAP     // Недостаточно очков действий
    case alreadyUsed        // Уже использована в этом ходу
    case notPlayerTurn      // Не ход игрока
}

struct ActionCardView: View {
    let card: ActionCard
    let state: CardPlayabilityState
    let level: Int
    let showDebugOutlines: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Отступ от верхней границы карточки до иконки (6px * 1.5 = 9px, padding уже 6px, добавляем 3px)
            Spacer().frame(height: 3)
            
            // Top: centered icon, level badge in top-right
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(UIStyle.Colors.mutedFill)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(iconColor)
                        .imageScale(.medium)
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 44, height: 44)
                .frame(maxWidth: .infinity, alignment: .center)

                if level > 1 {
                    Text("Lv\(level)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(UIStyle.Colors.inkPrimary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(UIStyle.Colors.mutedFill)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                        )
                }
            }

            // Отступ после иконки (8px * 1.5 = 12px)
            Spacer().frame(height: 12)

            // Name - фиксированная высота, текст масштабируется
            Text(titleRU)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.3)
                .frame(maxWidth: .infinity)
                .frame(height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.red, lineWidth: 2)
                        .opacity(showDebugOutlines ? 1 : 0)
                )

            // Отступ после названия
            Spacer().frame(height: 6)

            // Effect - адаптивное описание, занимает все доступное пространство
            GeometryReader { geo in
                VStack {
                    Spacer()
                    Text(effectRU)
                        .font(.caption)
                        .foregroundStyle(UIStyle.Colors.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(6)
                        .minimumScaleFactor(0.3)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.blue, lineWidth: 2)
                                .opacity(showDebugOutlines ? 1 : 0)
                        )
                    Spacer()
                }
            }
            .frame(maxHeight: .infinity)

            // Отступ перед стоимостью
            Spacer().frame(height: 8)

            // Cost
            Text("\(card.cost) ОД")
                .font(.caption.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(UIStyle.Colors.mutedFill)
                )
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(UIStyle.Colors.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(strokeColor, lineWidth: strokeWidth)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green, lineWidth: 3)
                .opacity(showDebugOutlines ? 1 : 0)
        )
        .opacity(opacity)
    }

    private var titleRU: String {
        ActionCardTexts.title(for: card.kind)
    }

    // MARK: - Icon System (синхронизировано со статусами)
    
    private var icon: String {
        switch card.kind {
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
        switch card.kind {
        // Статусные карты используют цвета статусов
        case .bleedPlus2, .bleedStrike: return Color.red
        case .weakPlus1, .weakDefend: return Color.orange
        case .stun1: return Color.purple
        
        // Базовые карты - нейтральный цвет
        default: return UIStyle.Colors.inkPrimary
        }
    }

    private var effectRU: String {
        ActionCardTexts.shortDescription(for: card.kind)
    }
    
    // MARK: - State-based styling
    
    private var opacity: Double {
        switch state {
        case .available:
            return 1.0
        case .insufficientAP, .alreadyUsed, .notPlayerTurn:
            return 0.60
        }
    }
    
    private var strokeColor: Color {
        switch state {
        case .available:
            return UIStyle.Colors.cardStroke
        case .insufficientAP:
            return UIStyle.Colors.cardStroke
        case .alreadyUsed:
            return Color.orange.opacity(0.6) // Оранжевая обводка для уже использованных
        case .notPlayerTurn:
            return UIStyle.Colors.cardStroke
        }
    }
    
    private var strokeWidth: CGFloat {
        switch state {
        case .alreadyUsed:
            return 2.0 // Более толстая обводка для использованных
        default:
            return 1.0
        }
    }
}
