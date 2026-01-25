import SwiftUI

struct CollectionCardCell: View {
    let card: ActionCardKind
    let isUnlocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 8) {
                // Icon section
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isUnlocked ? UIStyle.Colors.mutedFill : Color.black.opacity(0.7))
                    
                    if isUnlocked {
                        Text(icon)
                            .font(.system(size: 48))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(height: 100)
                
                // Title
                Text(isUnlocked ? titleRU : "???")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .frame(height: 36)
                
                // Cost
                if isUnlocked {
                    Text("\(cost) ОД")
                        .font(.caption2)
                        .foregroundStyle(UIStyle.Colors.inkSecondary)
                }
            }
            .padding(10)
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
    
    private var icon: String {
        switch card {
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
