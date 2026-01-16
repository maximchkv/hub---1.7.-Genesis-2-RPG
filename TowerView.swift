import SwiftUI

struct TowerView: View {
    @EnvironmentObject private var store: GameStore

    // MARK: - Layout constants (UI-KIT v2.0 - Redesign)
    private let contentCap: CGFloat = 380
    private let outerPad: CGFloat = 0

    private let topPad: CGFloat = 8
    private let toastToMeta: CGFloat = 10
    private let metaToStrategic: CGFloat = 12
    private let strategicToTactical: CGFloat = 12
    private let safeAreaBottomPadding: CGFloat = 160
    
    // Проценты высоты секций
    private let strategicSectionHeightPercent: CGFloat = 0.28
    private let tacticalSectionHeightPercent: CGFloat = 0.65

    // Toast
    private let toastHideDelay: Double = 1.2

    var body: some View {
        ZStack {
            UIStyle.background()
                .ignoresSafeArea()

            GeometryReader { geo in
                let available = max(0, geo.size.width - outerPad * 2)
                let contentWidth = min(available, contentCap)

                ScrollView {
                    VStack(spacing: 0) {
                        // Header (приглушённый)
                        headerRow
                            .frame(width: contentWidth, alignment: .center)
                            .padding(.top, topPad)

                        // Toast
                        toastView
                            .frame(width: contentWidth, alignment: .center)

                        Spacer().frame(height: toastToMeta)

                        // HP и прогресс (сбалансированно выделено)
                        topInfoRow
                            .frame(width: contentWidth, alignment: .center)

                        Spacer().frame(height: metaToStrategic)

                        // СТРАТЕГИЧЕСКАЯ СЕКЦИЯ (пустой блок для будущей реализации)
                        strategicSectionPlaceholder(contentWidth: contentWidth)

                        Spacer().frame(height: strategicToTactical)

                        // ТАКТИЧЕСКАЯ СЕКЦИЯ (большие карточки комнат)
                        tacticalSection(contentWidth: contentWidth)
                    }
                    .frame(maxWidth: .infinity)
                    .safeAreaPadding(.horizontal)
                    .safeAreaPadding(.bottom, safeAreaBottomPadding)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if store.run?.roomOptions.isEmpty ?? true {
                store.refreshRoomOptions()
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 12) {
            Button {
                store.goToHub()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
                    .accessibilityLabel("Back to Hub")
            }
            .buttonStyle(.plain)

            Text("Башня")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            // symmetric spacer so title stays centered
            Color.clear
                .frame(width: 28, height: 28)
        }
    }

    // MARK: - Toast

    private var toastView: some View {
        Group {
            if let toast = store.toast {
                Text(toast)
                    .font(.caption)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + toastHideDelay) {
                            if store.toast == toast {
                                store.toast = nil
                            }
                        }
                    }
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Meta

    private var topInfoRow: some View {
        HStack(alignment: .top, spacing: 12) {
            playerInfoRow
                .frame(maxWidth: .infinity, alignment: .leading)
            progressRow
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var playerInfoRow: some View {
        let hp = store.run?.playerHP ?? 0
        let maxHP = store.run?.playerMaxHP ?? 0
        let denom = max(1, maxHP)
        let hpFrac = Double(max(0, min(hp, denom))) / Double(denom)
        
        // Цветовая индикация HP
        let hpColor: Color = {
            if hpFrac > 0.6 { return .green }
            if hpFrac > 0.3 { return .yellow }
            return .red
        }()

        return metaCard(vertical: 8, horizontal: 12) {
            VStack(spacing: 10) {
                HStack {
                    Text("Здоровье")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Text("\(hp)/\(maxHP)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(hpColor)
                }

                TowerHPBar(fraction: hpFrac, color: hpColor)
                    .frame(height: 10)
            }
            .frame(minHeight: 48)
        }
        .accessibilityLabel("Здоровье \(hp) из \(maxHP).")
    }

    private var progressRow: some View {
        let floorInAct = store.run?.floorInAct ?? 0
        let bossIn = store.run?.floorsRemainingToBoss ?? 0
        let global = store.run?.globalFloor ?? 0
        let globalTotal = store.run?.globalFloorsTotal ?? 0

        return metaCard(vertical: 8, horizontal: 12) {
            HStack(spacing: 12) {
                metaChip(title: "Этаж", value: "\(floorInAct)/\(RunState.floorsPerAct + 1)")
                    .frame(maxWidth: .infinity)

                metaChip(title: "Босс", value: "\(bossIn)")
                    .frame(maxWidth: .infinity)

                metaChip(title: "Всего", value: "\(global)/\(globalTotal)")
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 48)
        }
        .accessibilityLabel("Этаж \(floorInAct). До босса \(bossIn). Всего \(global) из \(globalTotal).")
    }

    private func metaChip(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(minWidth: 0)
    }

    private func metaCard<Content: View>(
        vertical: CGFloat = 12,
        horizontal: CGFloat = 12,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        content()
            .padding(.vertical, vertical)
            .padding(.horizontal, horizontal)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
    }

    // MARK: - Strategic Section (Placeholder)
    
    private func strategicSectionPlaceholder(contentWidth: CGFloat) -> some View {
        VStack {
            // Пустой блок для будущей реализации стратегической секции
        }
        .padding(16)
        .frame(width: contentWidth)
        .frame(height: 248)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }

    // MARK: - Tactical Section (Большие карточки)

    private func tacticalSection(contentWidth: CGFloat) -> some View {
        let options = store.run?.roomOptions ?? []
        let standardSpacing: CGFloat = 12 // Same as metaToStrategic and strategicToTactical
        
        return VStack(spacing: standardSpacing) {
            if options.isEmpty {
                Text("Комнаты недоступны")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(options) { option in
                    TacticalRoomCardView(room: option) {
                        store.selectRoom(option)
                    }
                    .frame(width: contentWidth)
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(width: contentWidth)
        .frame(maxHeight: .infinity)
    }

}

// MARK: - Local helpers

private struct TowerHPBar: View {
    let fraction: Double
    let color: Color
    
    init(fraction: Double, color: Color = UIStyle.Colors.hpGreen) {
        self.fraction = fraction
        self.color = color
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let f = max(0, min(1, fraction))
            let fillW = CGFloat(f) * w

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 5)
                    .fill(color)
                    .frame(width: fillW)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .accessibilityHidden(true)
    }
}
