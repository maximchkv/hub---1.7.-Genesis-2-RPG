import SwiftUI

struct VictoryView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        UIStyle.Layout.ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: UIStyle.Spacing.l) {
                    // Header
                    VStack(alignment: .leading, spacing: UIStyle.Spacing.s) {
                        Text("Победа")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(UIStyle.Colors.inkPrimary)

                        Text("Вы прошли все 3 акта.")
                            .font(.callout)
                            .foregroundStyle(UIStyle.Colors.inkSecondary)
                    }
                    .padding(.bottom, UIStyle.Spacing.xs)

                    // Icon
                    Text("👑")
                        .font(.system(size: 72))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, UIStyle.Spacing.l)

                    // Stats
                    VStack(alignment: .leading, spacing: UIStyle.Spacing.xs) {
                        Text("Лучший этаж: \(store.meta.bestFloor)")
                            .font(.caption)
                        Text("Дней: \(store.meta.days)")
                            .font(.caption)
                        Text("Золото: \(store.meta.gold)")
                            .font(.caption)
                    }
                    .foregroundStyle(UIStyle.Colors.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, UIStyle.Spacing.m)

                    // Action
                    Button("Вернуться в хаб") {
                        store.finishRunAndReturnToHub()
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

