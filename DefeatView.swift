import SwiftUI

struct DefeatView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        UIStyle.Layout.ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: UIStyle.Spacing.l) {
                    // Header
                    VStack(alignment: .leading, spacing: UIStyle.Spacing.s) {
                        Text("Поражение")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(UIStyle.Colors.inkPrimary)

                        Text("Забег завершен.")
                            .font(.callout)
                            .foregroundStyle(UIStyle.Colors.inkSecondary)
                    }
                    .padding(.bottom, UIStyle.Spacing.xs)

                    // Action
                    Button("Вернуться в хаб") {
                        store.resetRun()
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
