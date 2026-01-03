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

            // 3) Description (placeholder text for now)
            Text(descriptionText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity)

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
        }
    }

    private var icon: String {
        switch card.kind {
        case .powerStrike: return "🗡️"
        case .defend: return "🛡️"
        case .doubleStrike: return "⚔️"
        case .counterStance: return "🔁"
        }
    }

    private var descriptionText: String {
        switch card.kind {
        case .powerStrike: return "Deal damage."
        case .defend: return "Gain block."
        case .doubleStrike: return "Deal damage twice."
        case .counterStance: return "Gain block and deal damage."
        }
    }
}
