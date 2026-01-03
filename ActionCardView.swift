import SwiftUI

struct ActionCardView: View {
    let card: ActionCard
    let disabled: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.largeTitle)

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)

            Text("\(card.cost) AP")
                .font(.caption2)
        }
        .padding(12)
        .frame(width: 96, height: 120)
        .background(disabled ? Color.gray.opacity(0.3) : Color.blue.opacity(0.3))
        .cornerRadius(12)
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
}
