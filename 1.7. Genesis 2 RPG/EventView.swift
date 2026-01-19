import SwiftUI

struct EventView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        UIStyle.Layout.ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: UIStyle.Spacing.l) {
                    // Header
                    VStack(alignment: .leading, spacing: UIStyle.Spacing.s) {
                        Text("Событие")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(UIStyle.Colors.inkPrimary)
                    }
                    .padding(.bottom, UIStyle.Spacing.xs)

                    // Content
                    if let event = store.event {
                        VStack(spacing: UIStyle.Spacing.m) {
                            Text(event.title)
                                .font(.headline)
                                .foregroundStyle(UIStyle.Colors.inkPrimary)

                            Text(event.text)
                                .font(.callout)
                                .foregroundStyle(UIStyle.Colors.inkSecondary)
                                .multilineTextAlignment(.center)

                            VStack(spacing: UIStyle.Spacing.s) {
                                ForEach(event.options) { opt in
                                    Button(opt.title) {
                                        store.chooseEventOption(opt)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .buttonStyle(UIStyle.PrimaryButtonStyle())
                                }
                            }
                            .padding(.top, UIStyle.Spacing.s)
                        }
                    } else {
                        VStack(spacing: UIStyle.Spacing.m) {
                            Text("Событие недоступно")
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

