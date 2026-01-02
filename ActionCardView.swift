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

            Text("\(card.cost) AP")
                .font(.caption2)
        }
        .padding(12)
        .frame(width: 90, height: 120)
        .background(disabled ? Color.gray.opacity(0.3) : Color.blue.opacity(0.3))
        .cornerRadius(12)
    }

    private var title: String {
        switch card.kind {
        case .strongAttack: return "Strike"
        case .doubleAttack: return "Double"
        case .defend: return "Defend"
        case .counter: return "Counter"
        }
    }

    private var icon: String {
        switch card.kind {
        case .strongAttack: return "🗡️"
        case .doubleAttack: return "⚔️"
        case .defend: return "🛡️"
        case .counter: return "🔁"
        }
    }
}
