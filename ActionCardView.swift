import SwiftUI

struct ActionCardView: View {
    let card: ActionCard
    let disabled: Bool

    var body: some View {
        VStack(spacing: 8) {

            // 1) Icon container (smaller than before, for emoji now, images later)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                Text(icon)
                    .font(.title2)
            }
            .frame(height: 44)

            // 2) Skill name
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity)

            // 3) Description (placeholder or effect text)
            Text(descriptionText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity)

            // 3.1) 031B: Effect row for status cards (icon + value)
            if let effect = statusEffectRow {
                HStack(spacing: 6) {
                    Image(systemName: effect.icon)
                        .font(.caption)
                    Text(effect.valueText)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // 4) AP cost
            Text("\(card.cost) AP")
                .font(.caption)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .opacity(disabled ? 0.6 : 1.0)
    }

    private var title: String {
        switch card.kind {
        case .powerStrike: return "Power Strike"
        case .defend: return "Guard"
        case .doubleStrike: return "Double Strike"
        case .counterStance: return "Counter Stance"
        case .bleedPlus2: return "Кровоток"
        case .weakPlus1: return "Ослабить"
        case .stun1: return "Оглушить"
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
        }
    }

    private var descriptionText: String {
        switch card.kind {
        case .powerStrike: return "Deal damage."
        case .defend: return "Gain block."
        case .doubleStrike: return "Deal damage twice."
        case .counterStance: return "Gain block and deal damage."
        case .bleedPlus2: return "Накладывает Кровотечение (+2)"
        case .weakPlus1: return "Накладывает Слабость (+1)"
        case .stun1: return "Накладывает Оглушение (1)"
        }
    }

    // 031B: effect row content for status cards
    private var statusEffectRow: (icon: String, valueText: String)? {
        switch card.kind {
        case .bleedPlus2:
            return ("drop.fill", "+2")
        case .weakPlus1:
            return ("arrow.down.circle.fill", "+1")
        case .stun1:
            return ("bolt.fill", "1")
        default:
            return nil
        }
    }
}
