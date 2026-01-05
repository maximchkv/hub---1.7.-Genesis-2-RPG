import SwiftUI

struct HubView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    // Layout
    private let horizontalPadding: CGFloat = 24
    private let verticalPadding: CGFloat = 24

    // Toast slot (фикс. высота, без сдвигов)
    private let toastSlotHeight: CGFloat = 34
    private let toastHideDelay: Double = 1.2

    var body: some View {
        ZStack {
            UIStyle.backgroundImage()
                .ignoresSafeArea()

            GeometryReader { geo in
                let availableWidth = max(0, geo.size.width - horizontalPadding * 2)
                let cap = widthCap(for: hSizeClass, windowWidth: geo.size.width)
                let contentWidth = min(availableWidth, cap)

                // Основной контент
                content(contentWidth: contentWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
                    .overlay(alignment: .topTrailing) {
                        debugButton
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                    }
            }
        }
        .onAppear { store.goToHub() }
    }

    // MARK: - Width cap

    private func widthCap(for sizeClass: UserInterfaceSizeClass?, windowWidth: CGFloat) -> CGFloat {
        switch sizeClass {
        case .compact:
            return 360 // iPhone
        case .regular:
            return windowWidth < 900 ? 600 : 720 // iPad / широкие окна
        default:
            return 360
        }
    }

    // MARK: - Content

    private func content(contentWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            headerCard
                .frame(width: contentWidth)

            toastSlot
                .frame(width: contentWidth)

            navGrid
                .frame(width: contentWidth)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 10) {

            // 5 колонок в одном блоке
            HStack(alignment: .top, spacing: 10) {
                metricCell(title: "Gold", value: "\(store.meta.gold)")
                metricCell(title: "Best", value: "\(store.meta.bestFloor)")
                metricCell(title: "Current", value: "\(store.run?.currentFloor ?? 0)")
                metricCell(title: "Days", value: "\(store.meta.days)")
                metricCell(title: "Streak", value: "\(store.run?.nonCombatStreak ?? 0)")
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                .stroke(UIStyle.Color.cardStroke, lineWidth: 1)
        )
    }

    private func metricCell(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(UIStyle.Color.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(value)
                .font(.headline)
                .foregroundStyle(UIStyle.Color.inkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Toast Slot (fixed height, no layout shifts)

    private var toastSlot: some View {
        ZStack {
            // Пустой слот всегда существует и держит высоту
            RoundedRectangle(cornerRadius: 999)
                .fill(SwiftUI.Color.clear)
                .frame(height: toastSlotHeight)

            if let toast = store.toast, !toast.isEmpty {
                Text(toast)
                    .font(.caption)
                    .foregroundStyle(UIStyle.Color.inkPrimary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(UIStyle.Color.cardStroke, lineWidth: 1)
                    )
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + toastHideDelay) {
                            if store.toast == toast {
                                store.toast = nil
                            }
                        }
                    }
            }
        }
        .frame(height: toastSlotHeight)
        .animation(.easeOut(duration: 0.18), value: store.toast)
    }

    // MARK: - Navigation cards (2 + 1)

    private var navGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                hubCardButton(
                    title: "Tower",
                    subtitle: "Climb the floors",
                    systemImage: "arrow.up.right.circle",
                    isEnabled: store.run != nil
                ) {
                    store.goToTower()
                }

                hubCardButton(
                    title: "Castle",
                    subtitle: "Build between runs",
                    systemImage: "building.columns",
                    isEnabled: true
                ) {
                    store.goToCastle()
                }
            }

            hubCardButton(
                title: "Cards",
                subtitle: "Library & collection",
                systemImage: "square.grid.2x2",
                isEnabled: true
            ) {
                store.goToCardLibrary()
            }
        }
    }

    private func hubCardButton(
        title: String,
        subtitle: String,
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .lineLimit(1)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(UIStyle.Color.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 0)
                }

                // Плейсхолдер под будущую картинку/арт
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .fill(SwiftUI.Color.black.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                            .stroke(UIStyle.Color.cardStroke, lineWidth: 1)
                    )
                    .frame(height: 84)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .stroke(UIStyle.Color.cardStroke, lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.35)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }

    // MARK: - Debug

    private var debugButton: some View {
        Button {
            store.endRun()
        } label: {
            Image(systemName: "ladybug")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(UIStyle.Color.inkPrimary)
                .padding(10)
                .background(.thinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(UIStyle.Color.cardStroke, lineWidth: 1)
                )
                .accessibilityLabel("End Run (debug)")
        }
        .buttonStyle(.plain)
    }
}
