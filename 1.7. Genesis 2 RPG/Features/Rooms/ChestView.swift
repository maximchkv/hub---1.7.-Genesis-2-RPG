import SwiftUI

struct ChestView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        UIStyle.Layout.ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: UIStyle.Spacing.l) {
                    // Header
                    VStack(alignment: .leading, spacing: UIStyle.Spacing.s) {
                        Text("Сундук")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(UIStyle.Colors.inkPrimary)
                    }
                    .padding(.bottom, UIStyle.Spacing.xs)

                    // Icon
                    Text("🧰")
                        .font(.system(size: 64))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, UIStyle.Spacing.l)

                    // Content
                    if let chest = store.chest {
                        if chest.isOpened, let art = chest.revealed {
                            // Result
                            VStack(alignment: .leading, spacing: UIStyle.Spacing.s) {
                                Text("\(art.icon) \(art.name)")
                                    .font(.headline)
                                    .foregroundStyle(UIStyle.Colors.textOnCard)
                                Text(art.description)
                                    .font(.callout)
                                    .foregroundStyle(UIStyle.Colors.textMuted)
                                Text("Бонус дохода: +\(art.incomeBonus)/день")
                                    .font(.caption)
                                    .foregroundStyle(UIStyle.Colors.textMuted)
                            }
                            .uiCard()
                            .padding(.bottom, UIStyle.Spacing.m)

                            Button("Отправить в замок и продолжить") {
                                store.claimChestRewardAndContinue()
                            }
                            .buttonStyle(UIStyle.PrimaryButtonStyle())
                        } else {
                            // Open
                            Button("Открыть сундук") {
                                store.openChest()
                            }
                            .buttonStyle(UIStyle.PrimaryButtonStyle())
                        }
                    } else {
                        VStack(spacing: UIStyle.Spacing.m) {
                            Text("Сундук недоступен")
                                .font(.caption)
                                .foregroundStyle(UIStyle.Colors.inkSecondary)
                            Button("Вернуться в башню") {
                                store.goToTower()
                            }
                            .buttonStyle(UIStyle.PrimaryButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, UIStyle.Spacing.xl)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
