import SwiftUI
import Foundation

// MARK: - PreferenceKey для позиции тактической секции
private struct TacticalTopYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TowerView: View {
    @EnvironmentObject private var store: GameStore
    @State private var tacticalTopY: CGFloat = 0

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
                let safeAreaBottom = geo.safeAreaInsets.bottom
                let safeAreaTop = geo.safeAreaInsets.top
                // Высота тактического блока = от текущей позиции до нижней границы safe area (совпадает с красной обводкой)
                let computedTacticalHeight = max(0, geo.size.height - safeAreaBottom - tacticalTopY)
                let tacticalHeight = computedTacticalHeight > 0 ? computedTacticalHeight : 200
                
                let initialMaxTacticalHeight = tacticalHeight
                
                // #region agent log
                let _ = {
                    debugLog(
                        hypothesisId: "A",
                        location: "TowerView.body.geometry",
                        message: "screenGeometry",
                        data: [
                            "screenWidth": geo.size.width,
                            "screenHeight": geo.size.height,
                            "safeAreaTop": safeAreaTop,
                            "safeAreaBottom": safeAreaBottom,
                            "safeAreaBottomPadding": safeAreaBottomPadding,
                            "initialMaxTacticalHeight": initialMaxTacticalHeight,
                            "tacticalTopY": tacticalTopY,
                            "computedTacticalHeight": computedTacticalHeight,
                            "contentWidth": contentWidth
                        ]
                    )
                }()
                // #endregion

                ScrollView {
                VStack(spacing: 0) {
                        // Header (приглушённый)
                    headerRow
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.top, topPad)
                            // #region agent log
                            .background(
                                GeometryReader { headerGeo in
                                    Color.clear
                                        .onAppear {
                                            debugLog(
                                                hypothesisId: "B",
                                                location: "TowerView.headerRow",
                                                message: "sectionHeight",
                                                data: [
                                                    "height": headerGeo.size.height,
                                                    "topPad": topPad,
                                                    "totalHeight": headerGeo.size.height + topPad
                                                ]
                                            )
                                        }
                                }
                            )
                            // #endregion

                    // Toast
                    toastView
                        .frame(width: contentWidth, alignment: .center)
                            // #region agent log
                            .background(
                                GeometryReader { toastGeo in
                                    Color.clear
                                        .onAppear {
                                            debugLog(
                                                hypothesisId: "B",
                                                location: "TowerView.toastView",
                                                message: "sectionHeight",
                                                data: [
                                                    "height": toastGeo.size.height
                                                ]
                                            )
                                        }
                                }
                            )
                            // #endregion

                    Spacer().frame(height: toastToMeta)

                        // HP и прогресс (сбалансированно выделено)
                    topInfoRow
                        .frame(width: contentWidth, alignment: .center)
                            // #region agent log
                            .background(
                                GeometryReader { infoGeo in
                                    Color.clear
                                        .onAppear {
                                            debugLog(
                                                hypothesisId: "B",
                                                location: "TowerView.topInfoRow",
                                                message: "sectionHeight",
                                                data: [
                                                    "height": infoGeo.size.height
                                                ]
                                            )
                                        }
                                }
                            )
                            // #endregion

                        Spacer().frame(height: metaToStrategic)

                        // СТРАТЕГИЧЕСКАЯ СЕКЦИЯ (пустой блок для будущей реализации)
                        strategicSectionPlaceholder(contentWidth: contentWidth)
                            // #region agent log
                            .background(
                                GeometryReader { strategicGeo in
                                    Color.clear
                                        .onAppear {
                                            debugLog(
                                                hypothesisId: "B",
                                                location: "TowerView.strategicSection",
                                                message: "sectionHeight",
                                                data: [
                                                    "height": strategicGeo.size.height
                                                ]
                                            )
                                        }
                                }
                            )
                            // #endregion

                        Spacer().frame(height: strategicToTactical)

                        // ТАКТИЧЕСКАЯ СЕКЦИЯ (большие карточки комнат)
                        tacticalSection(contentWidth: contentWidth, maxHeight: tacticalHeight, screenHeight: geo.size.height, safeAreaTop: safeAreaTop, safeAreaBottom: safeAreaBottom, safeAreaBottomPadding: safeAreaBottomPadding)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(key: TacticalTopYKey.self, value: proxy.frame(in: .global).minY)
                                }
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .onPreferenceChange(TacticalTopYKey.self) { value in
                        tacticalTopY = value
                        // #region agent log
                        // geo недоступен в onPreferenceChange, используем только value
                        debugLog(
                            hypothesisId: "H",
                            location: "TowerView.tacticalTopY",
                            message: "tacticalTopYChanged",
                            data: [
                                "tacticalTopY": value
                            ]
                        )
                        // #endregion
                    }
                    // #region agent log
                    .background(
                        GeometryReader { vstackGeo in
                            Color.clear
                                .onAppear {
                                    let headerHeight = 60.0 // approximate
                                    let toastHeight = 30.0 // approximate
                                    let infoHeight = 70.0 // approximate
                                    let strategicHeight = 248.0 // from code
                                    let spacerHeights = toastToMeta + metaToStrategic + strategicToTactical
                                    let estimatedAboveTactical = headerHeight + toastHeight + infoHeight + strategicHeight + spacerHeights
                                    let calculatedAvailableHeight = geo.size.height - safeAreaTop - safeAreaBottom - estimatedAboveTactical - safeAreaBottomPadding
                                    
                                    debugLog(
                                        hypothesisId: "C",
                                        location: "TowerView.VStack",
                                        message: "contentHeights",
                                        data: [
                                            "vstackTotalHeight": vstackGeo.size.height,
                                            "estimatedAboveTactical": estimatedAboveTactical,
                                            "calculatedAvailableHeight": calculatedAvailableHeight,
                                            "safeAreaTop": safeAreaTop,
                                            "safeAreaBottom": safeAreaBottom,
                                            "safeAreaBottomPadding": safeAreaBottomPadding,
                                            "spacing": [
                                                "toastToMeta": toastToMeta,
                                                "metaToStrategic": metaToStrategic,
                                                "strategicToTactical": strategicToTactical
                                            ]
                                        ]
                                    )
                                }
                        }
                    )
                    // #endregion
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

    private func tacticalSection(contentWidth: CGFloat, maxHeight: CGFloat, screenHeight: CGFloat, safeAreaTop: CGFloat, safeAreaBottom: CGFloat, safeAreaBottomPadding: CGFloat) -> some View {
        let options = store.run?.roomOptions ?? []
        let standardSpacing: CGFloat = 12 // Same as metaToStrategic and strategicToTactical
        
        return HStack(spacing: 0) {
            Spacer(minLength: 0)
            
            GeometryReader { geo in
                // Вычисляем доступную высоту блока: от текущей позиции до нижней границы safe area (с учётом стандартного отступа)
                let blockTopY = geo.frame(in: .global).minY
                let standardPadding: CGFloat = 12 // Стандартный отступ, такой же как metaToStrategic и strategicToTactical
                let baseBlockHeight = max(0, screenHeight - safeAreaBottom - standardPadding - blockTopY)
                let availableBlockHeight = baseBlockHeight * 1.2 // Увеличено на 20%
                
                // Вычисляем доступную высоту для карточек (высота блока - spacing между карточками)
                let cardCount = CGFloat(options.count)
                let totalSpacing = standardSpacing * max(0, cardCount - 1)
                let availableHeightForCards = max(0, availableBlockHeight - totalSpacing)
                let cardHeight = cardCount > 0 ? max(0, availableHeightForCards / cardCount) : 0
                
                // #region agent log
                let _ = {
                    debugLog(
                        hypothesisId: "F",
                        location: "TowerView.tacticalSection.calculation",
                        message: "cardHeightCalculation",
                        data: [
                            "cardCount": cardCount,
                            "totalSpacing": totalSpacing,
                            "blockTopY": blockTopY,
                            "availableBlockHeight": availableBlockHeight,
                            "availableHeightForCards": availableHeightForCards,
                            "cardHeight": cardHeight,
                            "screenHeight": screenHeight,
                            "safeAreaBottom": safeAreaBottom
                        ]
                    )
                }()
                // #endregion
                
                VStack(spacing: standardSpacing) {
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
                            .frame(height: cardHeight) // Фиксированная высота карточки
                        }
                    }
                }
                .frame(width: contentWidth)
                .frame(height: availableBlockHeight) // Жёстко ограничиваем высоту блока до нижней границы safe area
            }
            .frame(width: contentWidth) // Ограничиваем ширину GeometryReader
            
            Spacer(minLength: 0)
        }
    }

    // MARK: - Debug logging
    private func debugLog(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any]
    ) {
        let payload: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        let url = URL(fileURLWithPath: "/Users/max/Desktop/xcode projects/1.7. Genesis 2 RPG/.cursor/debug.log")
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonLine = String(data: jsonData, encoding: .utf8) else {
            return
        }
        let lineData = Data((jsonLine + "\n").utf8)
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(lineData)
            try? handle.close()
        } else {
            try? lineData.write(to: url)
        }
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
