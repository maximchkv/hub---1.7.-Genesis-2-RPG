import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RewardView: View {
    @EnvironmentObject private var store: GameStore

    @State private var isClaiming: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Награда")
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundStyle(UIStyle.Colors.inkPrimary)

                    Text("Выберите 1 улучшение")
                        .font(.callout)
                        .foregroundStyle(UIStyle.Colors.inkSecondary)
                }
                .padding(.bottom, 4)

                // Cards
                if let reward = store.reward {
                    VStack(spacing: 12) {
                        ForEach(reward.options, id: \.self) { kind in
                            Button {
                                claim(kind)
                            } label: {
                                RewardOptionCard(
                                    icon: icon(for: kind),
                                    title: title(for: kind),
                                    subtitle: "Улучшение: +1 уровень"
                                )
                            }
                            .buttonStyle(UIStyle.CardButtonStyle())
                            .disabled(isClaiming)
                        }
                    }
                } else {
                    Text("Награда недоступна (debug)")
                        .font(.caption)
                        .foregroundStyle(UIStyle.Colors.inkSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .background {
            UIStyle.background()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func claim(_ kind: ActionCardKind) {
        guard !isClaiming else { return }
        isClaiming = true

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        withAnimation(.easeOut(duration: 0.18)) {
            store.claimReward(kind)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isClaiming = false
        }
    }

    private func title(for kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "Силовой удар"
        case .defend: return "Защита"
        case .doubleStrike: return "Двойной удар"
        case .counterStance: return "Стойка контратаки"
        case .bleedPlus2: return "Кровоток"
        case .weakPlus1: return "Ослабить"
        case .stun1: return "Оглушить"
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "???"
        }
    }

    private func icon(for kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "🗡️"
        case .defend: return "🛡️"
        case .doubleStrike: return "⚔️"
        case .counterStance: return "🔁"
        case .bleedPlus2: return "🩸"
        case .weakPlus1: return "⬇️"
        case .stun1: return "⚡️"
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "❓"
        }
    }
}

private struct RewardOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(UIStyle.Colors.mutedFill)
                    .overlay(Circle().stroke(UIStyle.Colors.cardStroke, lineWidth: 1))

                Text(icon)
                    .font(.title3)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(UIStyle.Colors.inkSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkSecondary.opacity(0.55))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
    }
}
