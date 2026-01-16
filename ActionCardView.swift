import SwiftUI

struct ActionCardView: View {
    let card: ActionCard
    let disabled: Bool
    let level: Int

    var body: some View {
        VStack(spacing: 8) {
            // Top: centered icon, level badge in top-right
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(UIStyle.Colors.mutedFill)
                    Text(icon)
                        .font(.title2)
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

            // Name
            Text(titleRU)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity, alignment: .center)

            // Effect (compact, 1–2 lines)
            Text(effectRU)
                .font(.caption)
                .foregroundStyle(UIStyle.Colors.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)

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
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(UIStyle.Colors.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
        .opacity(disabled ? 0.60 : 1.0)
    }

    private var titleRU: String {
        switch card.kind {
        case .powerStrike: return "Мощный удар"
        case .defend: return "Защита"
        case .doubleStrike: return "Двойной удар"
        case .counterStance: return "Контратака"
        case .bleedPlus2: return "Кровоток"
        case .weakPlus1: return "Ослабить"
        case .stun1: return "Оглушить"
        case .bleedStrike: return "Кровавый удар"
        case .weakDefend: return "Ослабляющий щит"
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "???"
        }
    }

    private var icon: String {
        switch card.kind {
        case .powerStrike: return "🗡️"
        case .defend: return "🛡️"
        case .doubleStrike: return "⚔️"
        case .counterStance: return "🔁"
        case .bleedPlus2: return "🩸"
        case .weakPlus1: return "⬇️"
        case .stun1: return "⚡️"
        case .bleedStrike: return "🩸⚔️"
        case .weakDefend: return "🛡️⬇️"
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "❓"
        }
    }

    private var effectRU: String {
        switch card.kind {
        case .powerStrike: return "Наносит урон."
        case .defend: return "Даёт блок."
        case .doubleStrike: return "Наносит урон дважды."
        case .counterStance: return "Даёт блок и наносит урон."
        case .bleedPlus2: return "Накладывает Кровоток +2."
        case .weakPlus1: return "Накладывает Слабость +1."
        case .stun1: return "Накладывает Оглушение 1."
        case .bleedStrike: return "Если у врага Кровоток: урон = стаки × 3. Иначе: Кровоток +2."
        case .weakDefend: return "Слабость +1 врагу. Блок +4."
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "Будущая карта"
        }
    }
}
