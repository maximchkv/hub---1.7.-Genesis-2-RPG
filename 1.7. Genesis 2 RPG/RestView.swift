import SwiftUI

struct RestView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        UIStyle.Layout.ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: UIStyle.Spacing.l) {
                    // Header
                    VStack(alignment: .leading, spacing: UIStyle.Spacing.s) {
                        Text("Отдых")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(UIStyle.Colors.inkPrimary)

                        Text("Короткая передышка перед продолжением подъема.")
                            .font(.callout)
                            .foregroundStyle(UIStyle.Colors.inkSecondary)
                    }
                    .padding(.bottom, UIStyle.Spacing.xs)

                    // Icon
                    Text("🔥")
                        .font(.system(size: 64))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, UIStyle.Spacing.l)

                    // Action
                    Button("Восстановить +6 HP и продолжить") {
                        store.restHealAndContinue()
                    }
                    .buttonStyle(UIStyle.PrimaryButtonStyle())
                }
                .padding(.horizontal, UIStyle.Spacing.xl)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

