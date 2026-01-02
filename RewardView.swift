import SwiftUI

struct RewardView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Reward")
                .font(.title2)

            Text("Choose 1 upgrade")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let reward = store.reward {
                VStack(spacing: 12) {
                    ForEach(reward.options, id: \.self) { kind in
                        Button {
                            store.claimReward(kind)
                        } label: {
                            HStack(spacing: 12) {
                                Text(icon(for: kind))
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title(for: kind))
                                        .font(.headline)
                                    Text("Upgrade: +1 level")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("No reward (debug)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Reward")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func title(for kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "Power Strike"
        case .defend: return "Defend"
        case .doubleStrike: return "Double Strike"
        case .counterStance: return "Counter Stance"
        }
    }

    private func icon(for kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "🗡️"
        case .defend: return "🛡️"
        case .doubleStrike: return "⚔️"
        case .counterStance: return "🔁"
        }
    }
}
