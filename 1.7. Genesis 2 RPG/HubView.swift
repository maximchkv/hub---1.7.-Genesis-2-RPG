import SwiftUI

struct HubView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    // Layout
    private let horizontalPadding: CGFloat = 24
    private let verticalPadding: CGFloat = 24

    // Fixed header (028C/028D/028E)
    private let headerHeight: CGFloat = 92      // увеличено под 2 строки лейблов
    private let headerTopPad: CGFloat = 10
    private let headerBottomGap: CGFloat = 14

    // Metric slots (028E)
    private let metricLabelHeight: CGFloat = 28  // место под 2 строки caption2
    private let metricValueHeight: CGFloat = 22  // место под headline

    // Toast slot (фикс. высота, без сдвигов)
    private let toastSlotHeight: CGFloat = 34
    private let toastHideDelay: Double = 1.2

    // Shared card sizing/background (PATCH 032D/032 Castle image)
    private let hubCardHeight: CGFloat = 220
    private let hubThumbHeight: CGFloat = 132
    private let hubImageCorner: CGFloat = 16
    private let hubCardBgOpacity: Double = 0.85

    var body: some View {
        ZStack {
            UIStyle.background()
                .ignoresSafeArea()

            GeometryReader { geo in
                let availableWidth = max(0, geo.size.width - horizontalPadding * 2)
                let cap = widthCap(for: hSizeClass, windowWidth: geo.size.width)
                let contentWidth = min(availableWidth, cap)

                ZStack(alignment: .top) {

                    // CONTENT (scrollable) — ниже fixed header
                    ScrollView(.vertical) {
                        VStack(spacing: 16) {
                            toastSlot
                                .frame(width: contentWidth)

                            navGrid
                                .frame(width: contentWidth)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, verticalPadding)
                        .padding(.top, headerHeight + headerTopPad + headerBottomGap) // чтобы не залезать под header
                    }
                    .scrollIndicators(.hidden)

                    // HEADER (fixed)
                    headerCard
                        .frame(width: contentWidth, height: headerHeight)
                        .padding(.top, headerTopPad)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .padding(.horizontal, horizontalPadding)

                    // DEBUG (fixed)
                    debugButton
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        }
        // Удалено store.goToHub() из onAppear по T3-ARCH-BOOT-032E
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

    private var headerCard: some View {
        VStack(spacing: 10) {
            // 5 колонок в одном блоке
            HStack(alignment: .top, spacing: 10) {
                metricCell(title: "Gold", value: "\(store.meta.gold)")
                metricCell(title: "Best floor", value: "\(store.meta.bestFloor)")
                metricCell(title: "Current floor", value: "\(store.run?.currentFloor ?? 0)")
                metricCell(title: "Days", value: "\(store.meta.days)")
                metricCell(title: "Run streak", value: "\(store.run?.nonCombatStreak ?? 0)")
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
    }

    private func metricCell(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            // LABEL SLOT — фикс. высота, перенос до 2 строк, прижат вверх
            Text(title)
                .font(.caption2)
                .foregroundStyle(UIStyle.Colors.inkSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: metricLabelHeight, alignment: .top)

            // VALUE SLOT — фикс. высота, все значения на одной линии
            Text(value)
                .font(.headline)
                .foregroundStyle(UIStyle.Colors.inkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: metricValueHeight, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
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
        VStack(spacing: 18) { // зазор между верхним рядом и Cards
            HStack(spacing: 12) {
                // Tower card
                Button {
                    store.goToTower()
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: "arrow.up.right.circle")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tower")
                                    .font(.headline)
                                    .lineLimit(1)

                                Text("Climb the floors")
                                    .font(.caption)
                                    .foregroundStyle(UIStyle.Colors.inkSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }

                            Spacer(minLength: 0)
                        }

                        // Fixed thumbnail slot (unified with Castle)
                        Image("tower")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: hubThumbHeight)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: hubImageCorner))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .frame(height: hubCardHeight) // equal height for Tower/Castle
                    .background(.regularMaterial) // denser material without opacity
                    .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                            .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                    )
                    .opacity(store.run != nil ? 1.0 : 0.35)
                }
                .disabled(store.run == nil)
                .buttonStyle(.plain)

                // Castle card — same internal grid and thumbnail slot
                Button {
                    store.goToCastle()
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: "building.columns")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Castle")
                                    .font(.headline)
                                    .lineLimit(1)

                                Text("Build between runs")
                                    .font(.caption)
                                    .foregroundStyle(UIStyle.Colors.inkSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }

                            Spacer(minLength: 0)
                        }

                        // Fixed thumbnail slot (unified with Tower)
                        Image("castle")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: hubThumbHeight)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: hubImageCorner))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .frame(height: hubCardHeight) // equal height for Tower/Castle
                    .background(.regularMaterial) // denser material without opacity
                    .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                            .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            hubCardButton(
                title: "Cards",
                subtitle: "Library & collection",
                systemImage: "square.grid.2x2",
                isEnabled: true,
                showsPlaceholder: false
            ) { store.goToCardLibrary() }
        }
    }

    private func hubCardButton(
        title: String,
        subtitle: String,
        systemImage: String,
        isEnabled: Bool,
        showsPlaceholder: Bool = true,
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
                            .foregroundStyle(UIStyle.Colors.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 0)
                }

                if showsPlaceholder {
                    // Плейсхолдер остаётся высоким (168)
                    RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                        .fill(UIStyle.Colors.mutedFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                        )
                        .frame(height: 168)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
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
                .foregroundStyle(UIStyle.Colors.inkPrimary)
                .padding(10)
                .background(.thinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                )
                .accessibilityLabel("End Run (debug)")
        }
        .buttonStyle(.plain)
    }
}
